function Folder = list_filenames(Folder)
% Folder = list_filenames(Folder)
%
% little function for getting whatever is inside a folder, ignoring the
% stupid dots and turning everything into a string
%
% From iota-neurophys by Sophia Snipes, 2024.

Folder = deblank(string(ls(Folder)));

Folder(strcmp(Folder, ".")) = [];
Folder(strcmp(Folder, "..")) = [];