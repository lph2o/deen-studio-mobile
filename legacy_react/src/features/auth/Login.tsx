import { motion } from 'framer-motion';
import { signInWithPopup } from 'firebase/auth';
import { auth, googleProvider } from '../../firebase';
import { useNavigate } from 'react-router-dom';
import { Sparkles } from 'lucide-react';

export default function Login() {
  const navigate = useNavigate();

  const handleGoogleLogin = async () => {
    try {
      await signInWithPopup(auth, googleProvider);
      navigate('/dashboard');
    } catch (error) {
      console.error('Login failed:', error);
    }
  };

  return (
    <div className="bg-background text-on-background font-body min-h-screen flex flex-col items-center justify-center relative overflow-hidden">
      <div className="absolute top-[-10%] right-[-10%] w-[500px] h-[500px] bg-primary-container/20 rounded-full blur-[120px] pointer-events-none"></div>
      <div className="absolute bottom-[-10%] left-[-10%] w-[400px] h-[400px] bg-secondary/5 rounded-full blur-[100px] pointer-events-none"></div>

      <main className="w-full max-w-md px-6 z-10">
        <div className="mb-12 text-center">
          <div className="flex justify-center mb-8">
            <div className="w-16 h-16 bg-primary-container rounded-lg flex items-center justify-center shadow-2xl">
              <Sparkles className="text-primary w-8 h-8" />
            </div>
          </div>
          <h2 className="text-4xl font-headline font-extrabold text-primary mb-2">السَّلَامُ عَلَيْكُمْ</h2>
          <h1 className="text-2xl font-headline font-bold tracking-tight text-on-surface">As-salamu alaykum</h1>
          <p className="mt-4 text-on-surface-variant font-medium opacity-80">Welcome back to Deen Studio</p>
        </div>

        <div className="bg-surface-container-low p-8 rounded-lg shadow-[0_24px_48px_rgba(0,0,0,0.2)]">
          <button 
            onClick={handleGoogleLogin}
            className="w-full flex items-center justify-center gap-3 bg-surface-container-highest/40 hover:bg-surface-container-highest transition-colors py-4 rounded-md group"
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24">
              <path d="M12.48 10.92v3.28h7.84c-.24 1.84-.9 3.22-1.84 4.16-1.12 1.12-2.8 2.26-6 2.26-5.06 0-9.14-4.08-9.14-9.14s4.08-9.14 9.14-9.14c2.74 0 4.8 1.08 6.32 2.52l2.32-2.32C18.96 1.3 16.04 0 12.48 0 5.86 0 .5 5.36.5 12s5.36 12 11.98 12c3.6 0 6.32-1.18 8.44-3.4 2.18-2.18 2.88-5.3 2.88-7.92 0-.52-.04-1.04-.12-1.76H12.48z" fill="#EA4335"></path>
            </svg>
            <span className="text-sm font-bold text-on-surface">Continue with Google</span>
          </button>

          <div className="relative my-10">
            <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-outline-variant/15"></div></div>
            <div className="relative flex justify-center text-[10px] uppercase tracking-[0.2em] font-medium text-outline">
              <span className="bg-surface-container-low px-4">Or sign in with sanctuary</span>
            </div>
          </div>

          <form className="space-y-5" onSubmit={(e) => e.preventDefault()}>
            <div className="space-y-2">
              <label className="text-xs font-label uppercase tracking-widest text-on-surface-variant ml-1">Email Address</label>
              <input className="w-full bg-surface-container-high border-none focus:ring-1 focus:ring-secondary/40 text-on-surface rounded-md px-4 py-4 text-sm transition-all placeholder:text-outline/40" placeholder="name@example.com" type="email" />
            </div>
            <div className="space-y-2">
              <div className="flex justify-between items-center px-1">
                <label className="text-xs font-label uppercase tracking-widest text-on-surface-variant">Password</label>
                <a className="text-[10px] uppercase tracking-tighter text-secondary font-bold hover:underline" href="#">Forgot?</a>
              </div>
              <input className="w-full bg-surface-container-high border-none focus:ring-1 focus:ring-secondary/40 text-on-surface rounded-md px-4 py-4 text-sm transition-all placeholder:text-outline/40" placeholder="••••••••" type="password" />
            </div>
            <button className="w-full bg-gradient-to-r from-primary to-primary-container text-on-primary font-headline font-bold py-4 rounded-md shadow-lg shadow-primary-container/20 active:scale-95 transition-all mt-4">
              Sign In
            </button>
          </form>
        </div>

        <p className="mt-10 text-center text-sm text-on-surface-variant">
          Don't have an account? 
          <a className="text-secondary font-bold hover:underline ml-1" href="#">Create journey</a>
        </p>
      </main>
    </div>
  );
}
