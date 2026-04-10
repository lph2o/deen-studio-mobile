import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowLeft, Share2, Play, Pause, Scissors, Type, Music, Sparkles, Layers, Search, Check } from 'lucide-react';
import { quranService } from '../../services/quranService';
import { Surah, Project, Layer } from '../../types';
import { useEditorStore } from '../../store/useEditorStore';
import { auth, db } from '../../firebase';
import { doc, getDoc, setDoc } from 'firebase/firestore';

export default function Editor() {
  const { projectId } = useParams();
  const navigate = useNavigate();
  const [step, setStep] = useState<'surah' | 'edit' | 'export'>('surah');
  const [surahs, setSurahs] = useState<Surah[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const { currentProject, setProject, currentTime, setCurrentTime, isPlaying, togglePlay } = useEditorStore();

  useEffect(() => {
    const loadSurahs = async () => {
      const data = await quranService.getSurahs();
      setSurahs(data);
    };
    loadSurahs();
  }, []);

  const handleSurahSelect = async (surah: Surah) => {
    const newProject: Project = {
      id: projectId!,
      userId: auth.currentUser?.uid || '',
      title: `New Project - ${surah.englishName}`,
      surahId: surah.number,
      ayahRange: { start: 1, end: Math.min(surah.numberOfAyahs, 10) },
      reciterId: 'ar.alafasy',
      layers: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      status: 'draft'
    };
    
    setProject(newProject);
    setStep('edit');
    
    // Save to Firestore
    if (auth.currentUser) {
      await setDoc(doc(db, 'projects', projectId!), newProject);
    }
  };

  const filteredSurahs = surahs.filter(s => 
    s.englishName.toLowerCase().includes(searchQuery.toLowerCase()) || 
    s.number.toString().includes(searchQuery)
  );

  return (
    <div className="min-h-screen bg-background text-on-background font-body overflow-hidden flex flex-col">
      <header className="bg-surface-container sticky top-0 z-50 flex justify-between items-center w-full px-5 py-4 border-b border-outline-variant/10">
        <div className="flex items-center gap-4">
          <button onClick={() => navigate('/dashboard')} className="hover:bg-surface-container-highest transition-colors p-2 rounded-full">
            <ArrowLeft className="w-6 h-6 text-primary" />
          </button>
          <h1 className="font-headline font-bold text-lg tracking-tight text-on-surface">
            {currentProject?.title || 'New Project'}
          </h1>
        </div>
        <div className="flex items-center gap-3">
          <button 
            onClick={() => setStep('export')}
            className="bg-primary-container text-primary px-6 py-2 rounded-full font-headline font-bold text-sm tracking-wide hover:opacity-90 active:scale-95 transition-all"
          >
            EXPORT
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-hidden relative flex flex-col">
        <AnimatePresence mode="wait">
          {step === 'surah' && (
            <motion.div 
              key="surah-selection"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="flex-1 overflow-y-auto p-6 max-w-4xl mx-auto w-full"
            >
              <div className="mb-12">
                <h2 className="font-headline font-extrabold text-4xl mb-4 leading-tight">
                  Select a <span className="text-primary">Surah</span><br/>to Begin Your Project
                </h2>
                <p className="text-on-surface-variant max-w-lg leading-relaxed">
                  Choose from the 114 chapters of the Holy Quran. Your selection will initialize the studio with the full text and audio tracks.
                </p>
              </div>

              <div className="relative group mb-10">
                <Search className="absolute left-6 top-1/2 -translate-y-1/2 text-outline w-5 h-5" />
                <input 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full bg-surface-container-high border-none rounded-xl py-5 pl-14 pr-6 focus:ring-0 focus:bg-surface-bright transition-all text-on-surface placeholder:text-outline/60" 
                  placeholder="Search by name or number..." 
                  type="text" 
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pb-20">
                {filteredSurahs.map(surah => (
                  <div 
                    key={surah.number}
                    onClick={() => handleSurahSelect(surah)}
                    className="group relative bg-surface-container-low p-6 rounded-lg hover:bg-surface-container transition-all cursor-pointer border border-white/5"
                  >
                    <div className="flex justify-between items-start">
                      <div className="flex gap-4">
                        <div className="w-12 h-12 bg-primary-container flex items-center justify-center rounded-lg rotate-45 group-hover:rotate-0 transition-transform duration-500">
                          <span className="text-primary font-bold -rotate-45 group-hover:rotate-0 transition-transform">{surah.number}</span>
                        </div>
                        <div>
                          <h3 className="font-headline font-bold text-xl text-on-surface">{surah.englishName}</h3>
                          <p className="text-outline text-xs uppercase tracking-widest font-medium">{surah.englishNameTranslation}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-secondary mb-1 font-serif text-xl">{surah.name}</p>
                        <p className="text-on-surface-variant text-[10px] uppercase font-bold tracking-tighter">{surah.numberOfAyahs} Ayahs</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </motion.div>
          )}

          {step === 'edit' && (
            <motion.div 
              key="editor-main"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex-1 flex flex-col min-h-0"
            >
              <div className="flex-shrink-0 flex justify-center p-4">
                <div className="w-full max-w-4xl aspect-video bg-surface-container-lowest rounded-lg overflow-hidden shadow-2xl relative group">
                  <div className="absolute inset-0 bg-[url('https://picsum.photos/seed/spiritual/1920/1080')] bg-cover bg-center opacity-60"></div>
                  <div className="absolute inset-0 bg-black/30 backdrop-blur-[1px]"></div>
                  
                  <div className="absolute inset-0 flex flex-col items-center justify-center text-center p-8">
                    <h2 className="font-headline text-3xl md:text-5xl text-white drop-shadow-lg font-serif mb-4" dir="rtl">
                      فَبِأَيِّ آلَاء رَبِّكُمَا تُكَذِّبَانِ
                    </h2>
                    <p className="text-lg md:text-xl text-primary font-medium tracking-wide drop-shadow-md">
                      Lequel donc des bienfaits de votre Seigneur nierez-vous ?
                    </p>
                  </div>

                  <div className="absolute bottom-4 left-0 right-0 flex justify-center items-center gap-8 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button onClick={togglePlay} className="w-14 h-14 bg-secondary rounded-full flex items-center justify-center text-on-secondary shadow-lg active:scale-90 transition-transform">
                      {isPlaying ? <Pause className="w-8 h-8 fill-current" /> : <Play className="w-8 h-8 fill-current ml-1" />}
                    </button>
                  </div>
                </div>
              </div>

              <div className="flex-grow flex flex-col min-h-0 bg-surface-container rounded-t-lg overflow-hidden relative">
                <div className="flex items-center justify-between px-6 py-3 bg-surface-container-high border-b border-outline-variant/10">
                  <span className="text-xs font-mono text-on-surface-variant tracking-widest">00:12:45 / 03:20:00</span>
                  <div className="flex gap-4">
                    <button className="text-on-surface-variant hover:text-primary transition-colors"><span className="material-symbols-outlined text-xl">undo</span></button>
                    <button className="text-on-surface-variant hover:text-primary transition-colors"><span className="material-symbols-outlined text-xl">redo</span></button>
                  </div>
                </div>

                <div className="flex-grow overflow-x-auto relative py-8 px-4">
                  <div className="absolute top-0 bottom-0 left-1/3 w-[2px] bg-secondary z-30 shadow-[0_0_8px_rgba(233,195,73,0.6)]">
                    <div className="absolute -top-1 -left-1.5 w-4 h-4 bg-secondary rounded-full"></div>
                  </div>
                  
                  <div className="flex flex-col gap-4 min-w-max">
                    <div className="flex items-center gap-4">
                      <div className="w-20 text-[10px] uppercase tracking-tighter text-on-surface-variant/60 font-bold">Arabic</div>
                      <div className="h-10 w-64 bg-primary-container/40 rounded-sm border-l-4 border-primary flex items-center px-3">
                        <span className="text-[10px] text-primary truncate">فَبِأَيِّ آلَاء رَبِّكُمَا تُكَذِّبَانِ</span>
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="w-20 text-[10px] uppercase tracking-tighter text-on-surface-variant/60 font-bold">Trans</div>
                      <div className="h-10 w-64 bg-tertiary-container/30 rounded-sm border-l-4 border-tertiary flex items-center px-3">
                        <span className="text-[10px] text-tertiary truncate">Lequel donc des bienfaits...</span>
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="w-20 text-[10px] uppercase tracking-tighter text-on-surface-variant/60 font-bold">Video</div>
                      <div className="h-16 w-96 bg-surface-container-highest rounded-sm border border-outline-variant/10 overflow-hidden">
                        <img src="https://picsum.photos/seed/mountains/400/100" className="w-full h-full object-cover opacity-50" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-surface-container-highest/60 backdrop-blur-xl flex justify-around items-center px-4 pb-8 pt-3 border-t border-outline-variant/10">
                <button className="flex flex-col items-center justify-center text-on-surface/60 px-4 py-2 hover:text-primary transition-all">
                  <Scissors className="w-6 h-6 mb-1" />
                  <span className="text-[10px] uppercase tracking-widest font-medium">Trim</span>
                </button>
                <button className="flex flex-col items-center justify-center text-primary px-4 py-2">
                  <Type className="w-6 h-6 mb-1" />
                  <span className="text-[10px] uppercase tracking-widest font-medium">Text</span>
                </button>
                <button className="flex flex-col items-center justify-center text-on-surface/60 px-4 py-2 hover:text-primary transition-all">
                  <Music className="w-6 h-6 mb-1" />
                  <span className="text-[10px] uppercase tracking-widest font-medium">Audio</span>
                </button>
                <button className="flex flex-col items-center justify-center text-on-surface/60 px-4 py-2 hover:text-primary transition-all">
                  <Sparkles className="w-6 h-6 mb-1" />
                  <span className="text-[10px] uppercase tracking-widest font-medium">Effects</span>
                </button>
                <button className="flex flex-col items-center justify-center text-on-surface/60 px-4 py-2 hover:text-primary transition-all">
                  <Layers className="w-6 h-6 mb-1" />
                  <span className="text-[10px] uppercase tracking-widest font-medium">Overlay</span>
                </button>
              </div>
            </motion.div>
          )}

          {step === 'export' && (
            <motion.div 
              key="export-screen"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="flex-1 flex flex-col items-center justify-center p-6 space-y-12"
            >
              <div className="text-center space-y-4">
                <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-primary-container text-primary mb-4">
                  <Check className="w-10 h-10" />
                </div>
                <h2 className="text-4xl font-headline font-extrabold text-on-surface">Ready to Share</h2>
                <p className="text-on-surface-variant max-w-md mx-auto">Your cinematic Quranic creation is ready. Export for TikTok / Reels in stunning high definition.</p>
              </div>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 w-full max-w-2xl">
                {['TikTok', 'Reels', 'Shorts', 'Download'].map(dest => (
                  <div key={dest} className="aspect-square bg-surface-container-low rounded-lg flex flex-col items-center justify-center p-6 border border-outline-variant/10 hover:bg-primary-container/20 transition-all cursor-pointer group">
                    <div className="w-12 h-12 bg-surface-container-highest rounded-full flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                      <Share2 className="w-6 h-6" />
                    </div>
                    <span className="text-sm font-medium">{dest}</span>
                  </div>
                ))}
              </div>

              <button 
                onClick={() => navigate('/dashboard')}
                className="w-full max-w-md py-5 rounded-lg bg-gradient-to-r from-secondary to-secondary-container text-on-secondary font-headline font-extrabold text-xl shadow-2xl shadow-secondary/20 hover:scale-[1.02] active:scale-95 transition-all"
              >
                Back to Dashboard
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </main>
    </div>
  );
}
