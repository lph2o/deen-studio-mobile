import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, Sparkles, BookOpen } from 'lucide-react';

export default function Onboarding() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-background text-on-background font-body flex flex-col overflow-hidden relative selection:bg-primary/30">
      <header className="flex justify-center items-center w-full px-5 py-8">
        <h1 className="text-xl font-black text-primary tracking-widest font-headline">DEEN STUDIO</h1>
      </header>

      <main className="flex-1 flex flex-col items-center justify-center px-6 relative">
        <div className="absolute inset-0 bg-primary/5 blur-[80px] rounded-full pointer-events-none"></div>
        
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="w-full max-w-md aspect-[4/5] relative mb-12"
        >
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[280px] h-[560px] bg-surface-container rounded-[3rem] shadow-2xl border-[6px] border-surface-container-highest overflow-hidden transform -rotate-3 hover:rotate-0 transition-transform duration-700">
            <div className="h-full flex flex-col bg-surface-dim">
              <div className="h-6 flex justify-between px-6 items-end">
                <div className="text-[10px] text-on-surface/40">9:41</div>
                <div className="flex gap-1">
                  <div className="w-2 h-2 rounded-full bg-on-surface/20"></div>
                  <div className="w-2 h-2 rounded-full bg-on-surface/20"></div>
                </div>
              </div>

              <div className="flex-1 p-4 flex flex-col justify-center items-center text-center">
                <div className="w-full aspect-video rounded-lg overflow-hidden bg-surface-container-lowest mb-6 shadow-inner flex items-center justify-center p-4">
                  <p className="text-primary text-xl leading-relaxed font-serif">
                    بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
                  </p>
                </div>
                <div className="space-y-2 w-full">
                  <div className="h-1 bg-surface-container-highest rounded-full w-3/4 mx-auto"></div>
                  <div className="h-1 bg-surface-container-highest rounded-full w-1/2 mx-auto"></div>
                </div>
              </div>

              <div className="p-4 bg-surface/60 backdrop-blur-xl rounded-t-xl">
                <div className="flex items-center justify-between mb-3">
                  <span className="text-[10px] text-on-surface/60 font-medium uppercase tracking-tighter">00:12 / 00:45</span>
                  <Sparkles className="text-secondary w-4 h-4" />
                </div>
                <div className="h-12 bg-surface-container-lowest rounded-sm relative overflow-hidden flex items-center px-1 gap-1">
                  <div className="h-8 w-16 bg-primary-container rounded-sm border-l-2 border-primary"></div>
                  <div className="h-8 w-24 bg-surface-container-high rounded-sm opacity-50"></div>
                  <div className="h-8 w-12 bg-surface-container-high rounded-sm opacity-30"></div>
                  <div className="absolute left-1/3 top-0 bottom-0 w-0.5 bg-secondary shadow-[0_0_8px_rgba(233,195,73,0.5)] z-10"></div>
                </div>
              </div>
            </div>
          </div>

          <motion.div 
            initial={{ x: 20, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="absolute top-20 -right-4 bg-surface-container/80 backdrop-blur-md p-3 rounded-xl shadow-xl flex items-center gap-3 border border-outline-variant/10"
          >
            <Sparkles className="text-secondary w-5 h-5" />
            <div className="flex flex-col">
              <span className="text-[10px] text-on-surface/40 font-medium">EFFECTS</span>
              <span className="text-xs font-bold text-on-surface">Golden Glow</span>
            </div>
          </motion.div>

          <motion.div 
            initial={{ x: -20, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: 0.7 }}
            className="absolute bottom-32 -left-8 bg-surface-container/80 backdrop-blur-md p-3 rounded-xl shadow-xl flex items-center gap-3 border border-outline-variant/10"
          >
            <BookOpen className="text-primary w-5 h-5" />
            <div className="flex flex-col">
              <span className="text-[10px] text-on-surface/40 font-medium">SOURCE</span>
              <span className="text-xs font-bold text-on-surface">Surah Al-Fatihah</span>
            </div>
          </motion.div>
        </motion.div>

        <div className="w-full max-w-lg text-center space-y-6">
          <div className="space-y-2">
            <h2 className="text-4xl md:text-5xl font-extrabold font-headline tracking-tight text-on-surface leading-tight">
              Create Quranic <br/>
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-secondary">videos easily.</span>
            </h2>
            <p className="text-on-surface-variant max-w-xs mx-auto text-sm leading-relaxed">
              A professional studio for spiritual content creators, designed for focus and inspiration.
            </p>
          </div>

          <div className="pt-8">
            <button 
              onClick={() => navigate('/login')}
              className="group relative inline-flex items-center justify-center px-12 py-4 font-bold text-on-primary transition-all duration-300 bg-gradient-to-br from-primary to-inverse-primary rounded-full hover:scale-105 active:scale-95 shadow-lg shadow-primary/10"
            >
              <span className="relative tracking-widest text-sm uppercase">Next</span>
              <ArrowRight className="ml-2 w-5 h-5 transition-transform group-hover:translate-x-1" />
            </button>
          </div>
        </div>
      </main>

      <footer className="py-10 flex justify-center items-center gap-2">
        <div className="w-8 h-1.5 bg-primary rounded-full"></div>
        <div className="w-1.5 h-1.5 bg-surface-container-highest rounded-full"></div>
        <div className="w-1.5 h-1.5 bg-surface-container-highest rounded-full"></div>
      </footer>
    </div>
  );
}
