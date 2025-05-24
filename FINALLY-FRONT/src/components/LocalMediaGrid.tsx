import React from 'react';

interface LocalMediaGridProps {
  items: File[];
  type: 'audio' | 'image';
}

const LocalMediaGrid: React.FC<LocalMediaGridProps> = ({ items, type }) => {
  const renderItem = (file: File) => {
    if (type === 'audio') {
      return (
        <div className="p-4 border rounded-lg bg-gray-100">
          <div className="flex items-center space-x-4">
            <div className="w-12 h-12 flex items-center justify-center bg-gray-200 rounded-full">
              <i className="fas fa-music text-gray-600" />
            </div>
            <div className="flex-1">
              <p className="font-medium truncate">{file.name}</p>
              <p className="text-sm text-gray-500">
                {(file.size / (1024 * 1024)).toFixed(2)} MB
              </p>
            </div>
          </div>
        </div>
      );
    }

    return (
      <div className="aspect-square overflow-hidden rounded-lg">
        <img
          src={URL.createObjectURL(file)}
          alt={file.name}
          className="w-full h-full object-cover"
        />
      </div>
    );
  };

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      {items.map((file, index) => (
        <div key={`${file.name}-${index}`}>
          {renderItem(file)}
        </div>
      ))}
    </div>
  );
};

export default LocalMediaGrid;
