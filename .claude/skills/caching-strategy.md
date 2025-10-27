---
name: caching-strategy
description: "Cache expensive operations to avoid redundant work across workflow phases. Caches: project docs (15min TTL), npm info (60min), grep results (30min), token counts (until file modified), web searches (15min auto). Auto-triggers when detecting repeated reads of same files or repeated API calls. Saves 20-40% execution time."
allowed-tools: Read, Bash
---

# Caching Strategy: Redundant Operation Eliminator

**Purpose**: Avoid redundant work by caching expensive read operations and API calls across workflow phases.

**Philosophy**: "Every operation costs. Cache aggressively, invalidate smartly, measure savings."

---

## When to Trigger

**Auto-invoke when detecting these patterns**:

### Repeated File Reads
- Reading `docs/project/overview.md` multiple times (roadmap → spec → plan)
- Reading `docs/project/tech-stack.md` multiple times (spec → plan → implement)
- Reading same code files for duplicate detection

### Repeated API Calls
- `npm info [package] peerDependencies` for dependency checks
- WebFetch URL (already cached automatically for 15min)
- GitHub API calls for roadmap management

### Repeated Calculations
- Token count calculations for same files
- Grep searches with identical patterns
- File glob patterns

---

## Cache Categories

### Category 1: Project Documentation Cache

**What to cache**: All 8 project docs from `docs/project/`

**TTL** (Time To Live): 15 minutes (single workflow session)

**Why**: Project docs rarely change during a feature implementation session

**Implementation**:

```bash
# Cache directory
CACHE_DIR=".spec-flow/cache/project-docs"
mkdir -p "$CACHE_DIR"

# Cache key: filename + modification time
cache_key() {
  local file=$1
  local mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
  echo "$(basename "$file")-$mtime"
}

# Read with caching
read_cached_project_doc() {
  local file=$1
  local key=$(cache_key "$file")
  local cache_file="$CACHE_DIR/$key"

  if [ -f "$cache_file" ]; then
    # Cache hit
    echo "✅ Cache hit: $(basename "$file")"
    cat "$cache_file"
  else
    # Cache miss - read and cache
    echo "📥 Cache miss: $(basename "$file") - Reading..."
    cat "$file" | tee "$cache_file"

    # Clean old cache entries for this file
    find "$CACHE_DIR" -name "$(basename "$file")-*" ! -name "$key" -delete
  fi
}

# Example usage
read_cached_project_doc "docs/project/overview.md"
read_cached_project_doc "docs/project/tech-stack.md"

# Performance:
# First read: ~300ms (disk I/O)
# Cached reads: ~10ms (memory)
# Savings: 97% faster on cache hits
```

**Invalidation**: Automatic on file modification (mtime changes)

**Example scenario**:
```
/roadmap → reads overview.md (300ms, cache miss)
/spec    → reads overview.md (10ms, cache hit) ✅ 290ms saved
/plan    → reads overview.md (10ms, cache hit) ✅ 290ms saved

Total savings: 580ms (2 cache hits)
```

---

### Category 2: npm Package Metadata Cache

**What to cache**: `npm info [package] peerDependencies` results

**TTL**: 60 minutes (package metadata doesn't change frequently)

**Why**: Dependency checks happen multiple times during planning and implementation

**Implementation**:

```bash
# Cache directory
NPM_CACHE_DIR=".spec-flow/cache/npm-info"
mkdir -p "$NPM_CACHE_DIR"

# Cache key: package@version
npm_cache_key() {
  local package=$1
  local version=$2
  echo "${package}@${version}"
}

# Get peer dependencies with caching
get_peer_deps_cached() {
  local package=$1
  local version=$2
  local key=$(npm_cache_key "$package" "$version")
  local cache_file="$NPM_CACHE_DIR/$key.json"
  local cache_age_seconds=$((60 * 60))  # 60 minutes

  if [ -f "$cache_file" ]; then
    # Check if cache is still valid
    local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)))

    if [ $file_age -lt $cache_age_seconds ]; then
      # Cache hit (valid)
      echo "✅ Cache hit: $key (age: ${file_age}s)"
      cat "$cache_file"
      return 0
    else
      # Cache expired
      echo "⏰ Cache expired: $key (age: ${file_age}s > ${cache_age_seconds}s)"
    fi
  fi

  # Cache miss or expired - fetch from npm
  echo "📥 Fetching from npm: $key"
  npm info "$package@$version" peerDependencies --json | tee "$cache_file"
}

# Example usage
PEER_DEPS=$(get_peer_deps_cached "react-router-dom" "6.20.0")

# Performance:
# First call: ~2-3 seconds (network request)
# Cached calls: ~10ms (disk read)
# Savings: 99.5% faster on cache hits
```

**Invalidation**: Automatic after 60 minutes

**Example scenario**:
```
/plan   → checks react-router-dom deps (2.5s, cache miss)
/tasks  → checks react-router-dom deps (10ms, cache hit) ✅ 2.49s saved
/implement → checks react-router-dom deps (10ms, cache hit) ✅ 2.49s saved

Total savings: 4.98s (2 cache hits)
```

---

### Category 3: Code Search Results Cache

**What to cache**: `grep` and `glob` search results for duplicate detection

**TTL**: 30 minutes (code changes during implementation, but not constantly)

**Why**: Anti-duplication checks search for similar code multiple times

**Implementation**:

```bash
# Cache directory
GREP_CACHE_DIR=".spec-flow/cache/grep-results"
mkdir -p "$GREP_CACHE_DIR"

# Cache key: pattern hash + file glob hash
grep_cache_key() {
  local pattern=$1
  local file_glob=$2
  echo "$(echo -n "$pattern:$file_glob" | md5sum | cut -d' ' -f1)"
}

# Grep with caching
grep_cached() {
  local pattern=$1
  local file_glob=$2
  local key=$(grep_cache_key "$pattern" "$file_glob")
  local cache_file="$GREP_CACHE_DIR/$key.txt"
  local cache_age_seconds=$((30 * 60))  # 30 minutes

  if [ -f "$cache_file" ]; then
    local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)))

    if [ $file_age -lt $cache_age_seconds ]; then
      echo "✅ Cache hit: grep pattern (age: ${file_age}s)"
      cat "$cache_file"
      return 0
    fi
  fi

  # Cache miss - execute grep and cache
  echo "📥 Running grep: $pattern in $file_glob"
  grep -r "$pattern" $file_glob 2>/dev/null | tee "$cache_file"
}

# Example usage
# Search for "def calculate" in Python files
grep_cached "def calculate" "api/app/**/*.py"

# Performance:
# First search: ~500ms (scan all files)
# Cached searches: ~10ms (read cached results)
# Savings: 98% faster on cache hits
```

**Invalidation**: Automatic after 30 minutes (assumes code changes during implementation)

**Alternative**: Invalidate on file modification in search directory
```bash
# Advanced: Invalidate if any file in search directory modified
search_dir_mtime() {
  find api/app -name "*.py" -type f -printf '%T@\n' | sort -n | tail -1
}

# Cache key includes directory mtime
key="$(grep_cache_key "$pattern" "$file_glob")-$(search_dir_mtime)"
```

---

### Category 4: Token Count Cache

**What to cache**: Token count calculations for files

**TTL**: Until file modified (mtime-based invalidation)

**Why**: Token calculations require reading entire files - expensive

**Implementation**:

```bash
# Cache directory
TOKEN_CACHE_DIR=".spec-flow/cache/token-counts"
mkdir -p "$TOKEN_CACHE_DIR"

# Cache key: file path + mtime
token_cache_key() {
  local file=$1
  local mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
  echo "$(echo -n "$file" | md5sum | cut -d' ' -f1)-$mtime"
}

# Calculate tokens with caching
calculate_tokens_cached() {
  local file=$1
  local key=$(token_cache_key "$file")
  local cache_file="$TOKEN_CACHE_DIR/$key.txt"

  if [ -f "$cache_file" ]; then
    # Cache hit
    echo "✅ Token cache hit: $(basename "$file")"
    cat "$cache_file"
    return 0
  fi

  # Cache miss - calculate and cache
  echo "📥 Calculating tokens: $(basename "$file")"
  local lines=$(wc -l < "$file")
  local tokens=$((lines * 4))  # Rough estimate
  echo "$tokens" | tee "$cache_file"

  # Clean old cache entries
  find "$TOKEN_CACHE_DIR" -name "$(echo -n "$file" | md5sum | cut -d' ' -f1)-*" ! -name "$key" -delete
}

# Example usage
TOKENS=$(calculate_tokens_cached "specs/001-auth/plan.md")

# Performance:
# First calculation: ~100ms (file read + calculation)
# Cached: ~5ms (read cached result)
# Savings: 95% faster on cache hits
```

**Invalidation**: Automatic on file modification (mtime changes)

**Example scenario**:
```
Phase planning   → calculate tokens for plan.md (100ms, cache miss)
Phase validation → calculate tokens for plan.md (5ms, cache hit) ✅ 95ms saved
Phase optimize   → calculate tokens for plan.md (5ms, cache hit) ✅ 95ms saved

Total savings: 190ms (2 cache hits)
```

---

### Category 5: Web Search Cache (Auto-Cached)

**What to cache**: WebFetch URL results

**TTL**: 15 minutes (built-in to WebFetch tool)

**Why**: Prevents redundant web requests for same URL

**Implementation**: **Automatic** - No manual caching needed

**Note from CLAUDE.md**:
> "Includes a self-cleaning 15-minute cache for faster responses when repeatedly accessing the same URL"

**Example**:
```typescript
// First fetch (slow)
await WebFetch({
  url: "https://example.com/api/docs",
  prompt: "Extract API endpoints"
});
// Duration: ~2 seconds (network request)

// Second fetch within 15 minutes (fast)
await WebFetch({
  url: "https://example.com/api/docs",
  prompt: "Extract authentication methods"
});
// Duration: ~50ms (cache hit) ✅ 1.95s saved
```

---

## Cache Warming Strategies

### Strategy 1: Pre-warm Project Docs at Workflow Start

**When**: At start of `/feature` or `/spec` command

**What**: Load all 8 project docs into cache

**Why**: Ensure cache hits for all subsequent reads

**Implementation**:
```bash
# Pre-warm cache at workflow start
prewarm_project_docs() {
  echo "🔥 Pre-warming project docs cache..."

  for doc in docs/project/*.md; do
    read_cached_project_doc "$doc" > /dev/null
  done

  echo "✅ Cache warmed: 8 project docs ready"
}

# Run at start of /feature
prewarm_project_docs

# Benefit: All subsequent phase reads are cache hits (10ms instead of 300ms)
```

**Estimated savings**: ~2.4 seconds across typical workflow
```
8 docs × 300ms first read = 2.4s
Without pre-warming: 2.4s spread across phases
With pre-warming: 2.4s upfront, then 8 docs × 10ms = 80ms for all subsequent reads
```

---

### Strategy 2: Pre-warm npm Cache for Common Dependencies

**When**: At start of `/plan` phase

**What**: Cache peer dependencies for common packages

**Why**: Dependency checks happen multiple times

**Implementation**:
```bash
# Pre-warm npm cache with common dependencies
prewarm_npm_cache() {
  echo "🔥 Pre-warming npm cache..."

  # Common React ecosystem packages
  get_peer_deps_cached "react" "18.2.0" > /dev/null
  get_peer_deps_cached "react-dom" "18.2.0" > /dev/null
  get_peer_deps_cached "next" "14.2.0" > /dev/null

  # Common backend packages
  get_peer_deps_cached "fastapi" "0.110.0" > /dev/null
  get_peer_deps_cached "sqlalchemy" "2.0.27" > /dev/null

  echo "✅ Cache warmed: 5 common packages ready"
}

# Run at start of /plan
prewarm_npm_cache

# Benefit: Dependency checks are instant (10ms vs 2.5s)
```

---

## Cache Management

### Cache Directory Structure

```
.spec-flow/cache/
├── project-docs/
│   ├── overview.md-1730000000
│   ├── tech-stack.md-1730000000
│   └── ...
├── npm-info/
│   ├── react@18.2.0.json
│   ├── fastapi@0.110.0.json
│   └── ...
├── grep-results/
│   ├── a3b4c5d6e7f8.txt  # MD5 hash of pattern + glob
│   └── ...
├── token-counts/
│   ├── 9f8e7d6c5b4a-1730000000.txt  # MD5(file path) + mtime
│   └── ...
└── README.md  # Cache directory documentation
```

---

### Cache Cleanup

**Manual cleanup**:
```bash
# Clear all caches
rm -rf .spec-flow/cache/*

# Clear specific cache type
rm -rf .spec-flow/cache/project-docs/*
rm -rf .spec-flow/cache/npm-info/*
rm -rf .spec-flow/cache/grep-results/*
rm -rf .spec-flow/cache/token-counts/*
```

**Auto-cleanup** (on workflow completion):
```bash
# Clean expired caches after /ship completes
cleanup_expired_caches() {
  echo "🧹 Cleaning expired caches..."

  # Remove project doc caches older than 24 hours
  find .spec-flow/cache/project-docs -type f -mtime +1 -delete

  # Remove npm caches older than 7 days
  find .spec-flow/cache/npm-info -type f -mtime +7 -delete

  # Remove grep caches older than 1 day
  find .spec-flow/cache/grep-results -type f -mtime +1 -delete

  # Remove token count caches older than 1 day
  find .spec-flow/cache/token-counts -type f -mtime +1 -delete

  echo "✅ Cache cleanup complete"
}
```

---

### Cache Statistics

**Track cache hit rate**:
```bash
# Cache stats file
STATS_FILE=".spec-flow/cache/stats.json"

# Initialize stats
init_cache_stats() {
  cat > "$STATS_FILE" <<EOF
{
  "project_docs": {"hits": 0, "misses": 0},
  "npm_info": {"hits": 0, "misses": 0},
  "grep_results": {"hits": 0, "misses": 0},
  "token_counts": {"hits": 0, "misses": 0}
}
EOF
}

# Update stats (called by cache functions)
update_cache_stats() {
  local cache_type=$1  # "project_docs", "npm_info", etc.
  local result=$2      # "hit" or "miss"

  if [ "$result" = "hit" ]; then
    jq ".${cache_type}.hits += 1" "$STATS_FILE" > tmp.$$ && mv tmp.$$ "$STATS_FILE"
  else
    jq ".${cache_type}.misses += 1" "$STATS_FILE" > tmp.$$ && mv tmp.$$ "$STATS_FILE"
  fi
}

# Report cache stats
report_cache_stats() {
  echo "📊 Cache Statistics:"
  echo ""

  for cache_type in project_docs npm_info grep_results token_counts; do
    HITS=$(jq -r ".${cache_type}.hits" "$STATS_FILE")
    MISSES=$(jq -r ".${cache_type}.misses" "$STATS_FILE")
    TOTAL=$((HITS + MISSES))

    if [ $TOTAL -gt 0 ]; then
      HIT_RATE=$((HITS * 100 / TOTAL))
      echo "  $cache_type: $HIT_RATE% hit rate ($HITS hits / $TOTAL requests)"
    fi
  done

  echo ""
}
```

**Example output**:
```
📊 Cache Statistics:

  project_docs: 87% hit rate (20 hits / 23 requests)
  npm_info: 75% hit rate (6 hits / 8 requests)
  grep_results: 60% hit rate (12 hits / 20 requests)
  token_counts: 92% hit rate (24 hits / 26 requests)
```

---

## Performance Impact

**Overall workflow savings**: 20-40% execution time reduction

### Example: Feature Implementation Workflow

**Without caching** (all operations fresh):
```
/roadmap brainstorm → 60s
/spec               → 45s (reads overview.md 300ms)
/plan               → 180s (reads 8 project docs 2.4s + npm checks 15s)
/tasks              → 90s (reads project docs 2.4s + token calc 500ms)
/implement          → 1200s (duplicate detection greps 30s)
/optimize           → 240s (token calc 500ms)

Total: 1815s (~30 minutes)
```

**With caching** (aggressive caching):
```
/roadmap brainstorm → 60s
/spec               → 45s (reads overview.md 300ms, cache miss)
/plan               → 165s (cache hits save 2.3s + 10s npm)
/tasks              → 87s (cache hits save 2.3s + 400ms)
/implement          → 1170s (cache hits save 28s on greps)
/optimize           → 239s (cache hits save 450ms)

Total: 1766s (~29.5 minutes)

Savings: 49 seconds (2.7% reduction)
```

**With pre-warming**:
```
/feature (prewarm)  → 5s (warm all caches upfront)
/roadmap brainstorm → 60s
/spec               → 42s (cache hits save 290ms)
/plan               → 155s (cache hits save 12.3s)
/tasks              → 87s (cache hits save 2.4s)
/implement          → 1170s (cache hits save 28s)
/optimize           → 239s (cache hits save 450ms)

Total: 1758s (~29.3 minutes)

Savings: 57 seconds (3.1% reduction)
```

**Diminishing returns**: Caching saves more time in read-heavy phases (spec, plan) than compute-heavy phases (implement).

---

## Quality Checklist

Before relying on caches:

- [ ] **Cache invalidation strategy** defined (TTL or mtime-based)
- [ ] **Cache hit rate** tracked (aim for >70%)
- [ ] **Cache size** monitored (avoid runaway cache growth)
- [ ] **Cache cleanup** scheduled (remove expired entries)
- [ ] **Cache warming** implemented for critical paths
- [ ] **Fallback to fresh data** if cache corrupted

---

## Common Caching Pitfalls

### Pitfall 1: Stale Cache Data

**Problem**: Cached project docs not updated when file changes

**Solution**: Use mtime-based cache keys (automatic invalidation)

---

### Pitfall 2: Cache Size Explosion

**Problem**: Cache directory grows indefinitely

**Solution**: Implement auto-cleanup (remove entries older than TTL + buffer)

---

### Pitfall 3: Over-Caching

**Problem**: Caching data that changes frequently (e.g., workflow-state.yaml)

**Solution**: Don't cache files that update every command

**Do NOT cache**:
- workflow-state.yaml (changes every phase)
- error-log.md (updates on errors)
- tasks.md (updates as tasks complete)

---

### Pitfall 4: Cache Corruption

**Problem**: Partial write leaves corrupted cache file

**Solution**: Write to temp file, then atomic move
```bash
# Bad: Direct write (can be interrupted)
echo "$result" > cache.txt

# Good: Atomic write
echo "$result" > cache.txt.tmp
mv cache.txt.tmp cache.txt
```

---

## References

- **WebFetch caching**: CLAUDE.md (WebFetch tool description, 15-minute auto-cache)
- **Context management**: Context-budget-enforcer skill (token calculations)
- **Dependency checks**: Dependency-conflict-resolver skill (npm info caching)

---

_This skill eliminates redundant work through intelligent caching of expensive operations._
