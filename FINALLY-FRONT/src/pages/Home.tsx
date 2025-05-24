import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '../store';
import { setLocalMedia } from '../store/slices/mediaSlice';
import { scanLocalMedia } from '../utils/fileSystem';
import LocalMediaGrid from '../components/LocalMediaGrid';

const Home: React.FC = () => {
  const dispatch = useDispatch();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { localAudio, localImages } = useSelector((state: RootState) => state.media);

  const handleScanMedia = async () => {
    try {
      setIsLoading(true);
      setError(null);
      const media = await scanLocalMedia();
      dispatch(setLocalMedia(media));
      
      if (media.audio.length === 0 && media.images.length === 0) {
        setError('No media files found');
      }
    } catch (err) {
      setError('Error scanning files');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="container mx-auto p-4">
      <div className="mb-8 text-center">
        <h1 className="text-3xl font-bold mb-4">Personal Media Player</h1>
        <button
          className={`
            px-6 py-3 rounded-lg text-white font-medium
            ${isLoading 
              ? 'bg-gray-400 cursor-not-allowed' 
              : 'bg-blue-500 hover:bg-blue-600 transition-colors'}
          `}
          onClick={handleScanMedia}
          disabled={isLoading}
        >
          {isLoading ? 'Scanning...' : 'Select Media Folder'}
        </button>
        
        {error && (
          <div className="mt-4 p-3 bg-red-100 text-red-700 rounded-lg">
            {error}
          </div>
        )}
      </div>

      {(localAudio.length > 0 || localImages.length > 0) && (
        <div className="space-y-8">
          {localAudio.length > 0 && (
            <section>
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-2xl font-bold">Your Music</h2>
                <span className="text-gray-500">
                  {localAudio.length} files
                </span>
              </div>
              <LocalMediaGrid items={localAudio} type="audio" />
            </section>
          )}

          {localImages.length > 0 && (
            <section>
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-2xl font-bold">Your Images</h2>
                <span className="text-gray-500">
                  {localImages.length} images
                </span>
              </div>
              <LocalMediaGrid items={localImages} type="image" />
            </section>
          )}
        </div>
      )}

      {!isLoading && localAudio.length === 0 && localImages.length === 0 && (
        <div className="text-center text-gray-500 mt-8">
          <p>No files selected yet</p>
          <p className="text-sm mt-2">Click "Select Media Folder" to get started</p>
        </div>
      )}
    </div>
  );
};

export default Home;
