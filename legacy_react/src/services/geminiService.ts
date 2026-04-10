import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

export const geminiService = {
  async analyzeAudioForSync(audioUrl: string, ayahs: string[]) {
    const response = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: `Analyze the following audio and provide timestamps for each of these Quranic ayahs: ${ayahs.join(', ')}. Return the result in JSON format with 'ayah' and 'timestamp' fields.`,
      config: {
        responseMimeType: "application/json"
      }
    });
    return JSON.parse(response.text);
  },

  async suggestBackgroundMedia(surahTheme: string) {
    const response = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: `Suggest 5 visual themes or background media ideas for a video featuring the theme: ${surahTheme}. Focus on spiritual and cinematic visuals.`,
    });
    return response.text;
  }
};
