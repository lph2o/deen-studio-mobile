import { Surah, Ayah } from '../types';

const BASE_URL = 'https://api.alquran.cloud/v1';

export const quranService = {
  async getSurahs(): Promise<Surah[]> {
    const response = await fetch(`${BASE_URL}/surah`);
    const data = await response.json();
    return data.data;
  },

  async getSurah(number: number): Promise<Surah> {
    const response = await fetch(`${BASE_URL}/surah/${number}`);
    const data = await response.json();
    return data.data;
  },

  async getAyahs(surahNumber: number, edition: string = 'quran-uthmani'): Promise<Ayah[]> {
    const response = await fetch(`${BASE_URL}/surah/${surahNumber}/${edition}`);
    const data = await response.json();
    return data.data.ayahs;
  },

  async getAudioUrl(surahNumber: number, ayahNumber: number, reciter: string = 'ar.alafasy'): Promise<string> {
    // This is a simplified version. Real implementation would handle multiple reciters.
    return `https://cdn.islamic.network/quran/audio/128/${reciter}/${ayahNumber}.mp3`;
  }
};
