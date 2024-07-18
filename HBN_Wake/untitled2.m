close all
clc
figure
plot([1 2], [1 2], 'Color', [0 1 0])
axis off
title('hello')

chART.save_figure('Test', cd, PlotProps)

%%
% Your plot code here
saveas(gcf, 'myfigure.svg');

% Read the SVG file
svgFile = 'myfigure.svg';
fileText = fileread(svgFile);

% Replace color-interpolation from linearRGB to sRGB
fileText = strrep(fileText, 'color-interpolation:linearRGB;', 'color-interpolation:sRGB;');

% Write the modified content back to the SVG file
fid = fopen(svgFile, 'w');
fwrite(fid, fileText);
fclose(fid);