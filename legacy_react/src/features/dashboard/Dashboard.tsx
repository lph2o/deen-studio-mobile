import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { Plus, Menu, Sparkles, BookOpen, User as UserIcon, Play, History } from 'lucide-react';
import { auth } from '../../firebase';
import { useEffect, useState } from 'react';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { db } from '../../firebase';
import { Project } from '../../types';

export default function Dashboard() {
  const navigate = useNavigate();
  const [projects, setProjects] = useState<Project[]>([]);
  const user = auth.currentUser;

  useEffect(() => {
    const fetchProjects = async () => {
      if (user) {
        const q = query(collection(db, 'projects'), where('userId', '==', user.uid));
        const snapshot = await getDocs(q);
        setProjects(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Project)));
      }
    };
    fetchProjects();
  }, [user]);

  const handleCreateProject = () => {
    const newProjectId = Math.random().toString(36).substring(7);
    navigate(`/editor/${newProjectId}`);
  };

  return (
    <div className="min-h-screen bg-background text-on-background font-body selection:bg-primary/30">
      <header className="bg-surface-container sticky top-0 z-40 border-b border-outline-variant/10">
        <div className="flex justify-between items-center w-full px-5 py-4 max-w-7xl mx-auto">
          <div className="flex items-center gap-4">
            <button className="text-primary hover:bg-surface-container-highest transition-colors p-2 rounded-full">
              <Menu className="w-6 h-6" />
            </button>
            <h1 className="text-xl font-black text-primary tracking-widest uppercase font-headline">Deen Studio</h1>
          </div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full overflow-hidden bg-surface-container-highest flex items-center justify-center border border-primary/20">
              {user?.photoURL ? (
                <img src={user.photoURL} alt="Profile" className="w-full h-full object-cover" />
              ) : (
                <UserIcon className="text-primary w-6 h-6" />
              )}
            </div>
          </div>
        </div>
      </header>

      <main className="pb-32 pt-10 px-5 max-w-7xl mx-auto space-y-12">
        <section>
          <div className="relative overflow-hidden rounded-lg bg-surface-container-low min-h-[220px] flex flex-col justify-center p-8">
            <div className="absolute inset-0 opacity-[0.03] pointer-events-none bg-[url('https://www.transparenttextures.com/patterns/islamic-art.png')]"></div>
            <div className="relative z-10 flex flex-col items-start gap-4">
              <span className="bg-primary-container text-primary px-3 py-1 rounded-full text-xs font-bold tracking-widest uppercase">Workspace</span>
              <h2 className="font-headline text-3xl font-bold tracking-tight text-on-surface max-w-md">
                Bring your spiritual vision <br/>to life today.
              </h2>
              <button 
                onClick={handleCreateProject}
                className="mt-4 flex items-center gap-3 bg-gradient-to-r from-secondary to-secondary-container text-on-secondary-container px-8 py-4 rounded-lg font-bold transition-all hover:shadow-[0_0_20px_rgba(233,195,73,0.3)] active:scale-95"
              >
                <Plus className="w-5 h-5" />
                Create New Project
              </button>
            </div>
            <div className="absolute top-[-20%] right-[-5%] w-64 h-64 bg-primary/10 blur-[100px] rounded-full"></div>
          </div>
        </section>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-10">
          <div className="md:col-span-2 space-y-6">
            <div className="flex justify-between items-end">
              <h3 className="font-headline text-xl font-bold text-on-surface">Recent Projects</h3>
              <button className="text-primary text-sm font-medium hover:underline">View all</button>
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              {projects.length > 0 ? projects.map(project => (
                <div key={project.id} className="bg-surface-container-low rounded-lg p-3 group cursor-pointer hover:bg-surface-container transition-colors">
                  <div className="aspect-video rounded-md overflow-hidden mb-3 relative bg-surface-container-highest">
                    <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/40">
                      <Play className="text-white w-10 h-10" />
                    </div>
                    <div className="absolute bottom-2 right-2 bg-black/60 px-2 py-0.5 rounded text-[10px] text-white">00:45</div>
                  </div>
                  <h4 className="font-medium text-sm text-on-surface truncate">{project.title}</h4>
                  <p className="text-xs text-on-surface-variant mt-1">Edited {new Date(project.updatedAt).toLocaleDateString()}</p>
                </div>
              )) : (
                <div className="col-span-full py-12 text-center bg-surface-container-low rounded-lg border border-dashed border-outline-variant/30">
                  <History className="w-12 h-12 text-outline/30 mx-auto mb-4" />
                  <p className="text-on-surface-variant">No projects yet. Start your first creation!</p>
                </div>
              )}
            </div>
          </div>

          <div className="space-y-6">
            <h3 className="font-headline text-xl font-bold text-on-surface">Popular Templates</h3>
            <div className="bg-surface-container-low rounded-lg p-4 flex flex-col gap-4">
              <div className="flex items-center gap-4 p-3 rounded-md hover:bg-surface-container-highest transition-colors cursor-pointer group">
                <div className="w-12 h-12 rounded bg-primary-container flex items-center justify-center group-hover:scale-110 transition-transform">
                  <Sparkles className="text-primary w-6 h-6" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-on-surface">Quran Stories</p>
                  <p className="text-[11px] text-on-surface-variant">Cinematic vertical format</p>
                </div>
              </div>
              <div className="flex items-center gap-4 p-3 rounded-md hover:bg-surface-container-highest transition-colors cursor-pointer group">
                <div className="w-12 h-12 rounded bg-tertiary-container flex items-center justify-center group-hover:scale-110 transition-transform">
                  <BookOpen className="text-tertiary w-6 h-6" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-on-surface">Daily Reminders</p>
                  <p className="text-[11px] text-on-surface-variant">Minimal typography focus</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>

      <nav className="fixed bottom-0 left-0 w-full z-50 flex justify-around items-center px-4 pb-8 pt-3 bg-background/60 backdrop-blur-xl border-t border-outline-variant/10">
        <button className="flex flex-col items-center justify-center text-primary px-6 py-2">
          <span className="material-symbols-outlined" style={{ fontVariationSettings: "'FILL' 1" }}>home</span>
          <span className="text-[10px] uppercase tracking-widest font-medium mt-1">Home</span>
        </button>
        <button className="flex flex-col items-center justify-center text-on-surface/40 px-6 py-2 hover:text-primary transition-colors">
          <span className="material-symbols-outlined">auto_awesome</span>
          <span className="text-[10px] uppercase tracking-widest font-medium mt-1">Templates</span>
        </button>
        <button className="flex flex-col items-center justify-center text-on-surface/40 px-6 py-2 hover:text-primary transition-colors">
          <span className="material-symbols-outlined">movie_edit</span>
          <span className="text-[10px] uppercase tracking-widest font-medium mt-1">Projects</span>
        </button>
        <button className="flex flex-col items-center justify-center text-on-surface/40 px-6 py-2 hover:text-primary transition-colors">
          <span className="material-symbols-outlined">person</span>
          <span className="text-[10px] uppercase tracking-widest font-medium mt-1">Profile</span>
        </button>
      </nav>
    </div>
  );
}
