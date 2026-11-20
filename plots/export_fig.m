function export_fig(fig, folder, name, dpi)
% Save a plot as a PNG in the report figure folder.
    if nargin < 4
        dpi = 150;
    end
    if ~isfolder(folder)
        mkdir(folder);
    end
    [~, name, extension] = fileparts(name);
    if isempty(extension)
        extension = '.png';
    end
    set(fig, 'Color', 'w');
    exportgraphics(fig, fullfile(folder, [name extension]), ...
        'Resolution', dpi, 'BackgroundColor', 'white');
end
