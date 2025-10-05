'use client';

import { useState } from 'react';
import Link from 'next/link';

type TaskStatus = 'pending' | 'in_progress' | 'completed';

interface Task {
  id: string;
  title: string;
  description: string;
  status: TaskStatus;
  createdAt: Date;
}

const initialTasks: Task[] = [
  { id: '1', title: 'Design homepage mockups', description: 'Create wireframes and high-fidelity designs', status: 'completed', createdAt: new Date('2025-09-28') },
  { id: '2', title: 'Implement authentication system', description: 'Set up user login and registration', status: 'in_progress', createdAt: new Date('2025-09-29') },
  { id: '3', title: 'Build API endpoints', description: 'Create RESTful API for task management', status: 'pending', createdAt: new Date('2025-09-30') },
  { id: '4', title: 'Write unit tests', description: 'Achieve 80% code coverage', status: 'pending', createdAt: new Date('2025-10-01') },
  { id: '5', title: 'Setup CI/CD pipeline', description: 'Configure automated testing and deployment', status: 'in_progress', createdAt: new Date('2025-10-02') },
];

export default function Dashboard() {
  const [tasks, setTasks] = useState<Task[]>(initialTasks);
  const [filter, setFilter] = useState<TaskStatus | 'all'>('all');

  const filteredTasks = filter === 'all' ? tasks : tasks.filter(task => task.status === filter);

  const getStatusColor = (status: TaskStatus) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
      case 'in_progress': return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200';
      case 'pending': return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200';
    }
  };

  const getStatusLabel = (status: TaskStatus) => {
    switch (status) {
      case 'completed': return 'Completed';
      case 'in_progress': return 'In Progress';
      case 'pending': return 'Pending';
    }
  };

  const taskCounts = {
    all: tasks.length,
    pending: tasks.filter(t => t.status === 'pending').length,
    in_progress: tasks.filter(t => t.status === 'in_progress').length,
    completed: tasks.filter(t => t.status === 'completed').length,
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800">
      {/* Navigation */}
      <nav className="border-b border-slate-200 dark:border-slate-700 bg-white/50 dark:bg-slate-900/50 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <Link href="/" className="flex items-center gap-2">
              <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg"></div>
              <span className="text-xl font-bold text-slate-900 dark:text-white">TaskFlow</span>
            </Link>
            <div className="flex gap-4">
              <Link href="/" className="px-4 py-2 text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white transition-colors">
                Home
              </Link>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-slate-900 dark:text-white mb-2">Task Dashboard</h1>
          <p className="text-slate-600 dark:text-slate-300">Manage your workflow with Spec-Flow methodology</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <div className="bg-white dark:bg-slate-800 p-6 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
            <div className="text-2xl font-bold text-slate-900 dark:text-white">{taskCounts.all}</div>
            <div className="text-sm text-slate-600 dark:text-slate-300">Total Tasks</div>
          </div>
          <div className="bg-white dark:bg-slate-800 p-6 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
            <div className="text-2xl font-bold text-gray-900 dark:text-white">{taskCounts.pending}</div>
            <div className="text-sm text-slate-600 dark:text-slate-300">Pending</div>
          </div>
          <div className="bg-white dark:bg-slate-800 p-6 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
            <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">{taskCounts.in_progress}</div>
            <div className="text-sm text-slate-600 dark:text-slate-300">In Progress</div>
          </div>
          <div className="bg-white dark:bg-slate-800 p-6 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700">
            <div className="text-2xl font-bold text-green-600 dark:text-green-400">{taskCounts.completed}</div>
            <div className="text-sm text-slate-600 dark:text-slate-300">Completed</div>
          </div>
        </div>

        {/* Filters */}
        <div className="flex gap-2 mb-6">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'all'
                ? 'bg-blue-600 text-white'
                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700'
            }`}
          >
            All
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'pending'
                ? 'bg-blue-600 text-white'
                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700'
            }`}
          >
            Pending
          </button>
          <button
            onClick={() => setFilter('in_progress')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'in_progress'
                ? 'bg-blue-600 text-white'
                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700'
            }`}
          >
            In Progress
          </button>
          <button
            onClick={() => setFilter('completed')}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              filter === 'completed'
                ? 'bg-blue-600 text-white'
                : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700'
            }`}
          >
            Completed
          </button>
        </div>

        {/* Task List */}
        <div className="space-y-4">
          {filteredTasks.map(task => (
            <div
              key={task.id}
              className="bg-white dark:bg-slate-800 p-6 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 hover:shadow-md transition-shadow"
            >
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">{task.title}</h3>
                <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(task.status)}`}>
                  {getStatusLabel(task.status)}
                </span>
              </div>
              <p className="text-slate-600 dark:text-slate-300 mb-3">{task.description}</p>
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-500 dark:text-slate-400">
                  Created {task.createdAt.toLocaleDateString()}
                </span>
                <button className="text-blue-600 dark:text-blue-400 hover:underline text-sm font-medium">
                  Edit
                </button>
              </div>
            </div>
          ))}
        </div>

        {filteredTasks.length === 0 && (
          <div className="text-center py-12">
            <p className="text-slate-600 dark:text-slate-300">No tasks found in this category.</p>
          </div>
        )}
      </div>
    </div>
  );
}
