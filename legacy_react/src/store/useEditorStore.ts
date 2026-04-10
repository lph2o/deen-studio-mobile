import { create } from 'zustand';
import { Project, Layer } from '../types';

interface EditorState {
  currentProject: Project | null;
  selectedLayerId: string | null;
  currentTime: number;
  isPlaying: boolean;
  setProject: (project: Project | null) => void;
  addLayer: (layer: Layer) => void;
  updateLayer: (layerId: string, updates: Partial<Layer>) => void;
  removeLayer: (layerId: string) => void;
  setSelectedLayer: (layerId: string | null) => void;
  setCurrentTime: (time: number) => void;
  togglePlay: () => void;
}

export const useEditorStore = create<EditorState>((set) => ({
  currentProject: null,
  selectedLayerId: null,
  currentTime: 0,
  isPlaying: false,
  setProject: (project) => set({ currentProject: project }),
  addLayer: (layer) => set((state) => ({
    currentProject: state.currentProject ? {
      ...state.currentProject,
      layers: [...state.currentProject.layers, layer]
    } : null
  })),
  updateLayer: (layerId, updates) => set((state) => ({
    currentProject: state.currentProject ? {
      ...state.currentProject,
      layers: state.currentProject.layers.map(l => l.id === layerId ? { ...l, ...updates } : l)
    } : null
  })),
  removeLayer: (layerId) => set((state) => ({
    currentProject: state.currentProject ? {
      ...state.currentProject,
      layers: state.currentProject.layers.filter(l => l.id !== layerId)
    } : null
  })),
  setSelectedLayer: (layerId) => set({ selectedLayerId: layerId }),
  setCurrentTime: (time) => set({ currentTime: time }),
  togglePlay: () => set((state) => ({ isPlaying: !state.isPlaying })),
}));
