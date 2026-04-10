export interface User {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  createdAt: string;
  role: 'user' | 'admin';
}

export interface Project {
  id: string;
  userId: string;
  title: string;
  surahId: number;
  ayahRange: {
    start: number;
    end: number;
  };
  reciterId: string;
  layers: Layer[];
  createdAt: string;
  updatedAt: string;
  status: 'draft' | 'rendering' | 'completed';
  exportUrl?: string;
}

export interface Layer {
  id: string;
  type: 'video' | 'audio' | 'text';
  startTime: number;
  duration: number;
  content: any;
  style?: any;
}

export interface Surah {
  number: number;
  name: string;
  englishName: string;
  englishNameTranslation: string;
  numberOfAyahs: number;
  revelationType: string;
}

export interface Ayah {
  number: number;
  text: string;
  numberInSurah: number;
  juz: number;
  manzil: number;
  page: number;
  ruku: number;
  hizbQuarter: number;
  sajda: boolean;
}
