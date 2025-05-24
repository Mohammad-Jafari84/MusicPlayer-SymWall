import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface MediaState {
  localAudio: File[];
  localImages: File[];
  // ...existing code...
}

const initialState: MediaState = {
  localAudio: [],
  localImages: [],
  // ...existing code...
};

const mediaSlice = createSlice({
  name: 'media',
  initialState,
  reducers: {
    setLocalMedia: (state, action: PayloadAction<{ audio: File[], images: File[] }>) => {
      state.localAudio = action.payload.audio;
      state.localImages = action.payload.images;
    },
    // ...existing code...
  },
});

export const { setLocalMedia } = mediaSlice.actions;
export default mediaSlice.reducer;
