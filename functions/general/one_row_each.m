function UniqueMetadata = one_row_each(Metadata, UniqueIdentifyingColumn)
% This will select the first entry for each unique element in the
% UniqueIdentifyingColumn. If you want it to be based on a specific
% criteria, first sort the metadata by that criteria.

UniqueMetadata = table();

UniqueItems = unique(Metadata.(UniqueIdentifyingColumn));

for UniqueId = UniqueItems'
    if isnumeric(Metadata.(UniqueIdentifyingColumn)(1))
        MiniTable = Metadata(Metadata.(UniqueIdentifyingColumn)==UniqueId(1), :);
    else
        MiniTable = Metadata(strcmp(Metadata.(UniqueIdentifyingColumn), UniqueId{1}), :);
    end

    UniqueMetadata = cat(1, UniqueMetadata, MiniTable(1, :));
end