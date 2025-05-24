export const getSupportedAudioFormats = () => ['.mp3', '.wav', '.ogg', '.m4a'];
export const getSupportedImageFormats = () => ['.jpg', '.jpeg', '.png', '.gif'];

export const scanLocalMedia = async () => {
  try {
    const dirHandle = await window.showDirectoryPicker();
    const files = {
      audio: [] as File[],
      images: [] as File[]
    };

    const scan = async (handle: FileSystemDirectoryHandle) => {
      for await (const entry of handle.values()) {
        if (entry.kind === 'file') {
          const file = await entry.getFile();
          const ext = `.${file.name.split('.').pop()?.toLowerCase()}`;
          
          if (getSupportedAudioFormats().includes(ext)) {
            files.audio.push(file);
          } else if (getSupportedImageFormats().includes(ext)) {
            files.images.push(file);
          }
        } else if (entry.kind === 'directory') {
          await scan(entry);
        }
      }
    };

    await scan(dirHandle);
    return files;
  } catch (error) {
    console.error('Error scanning local media:', error);
    return { audio: [], images: [] };
  }
};
