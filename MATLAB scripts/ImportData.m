function output=ImportData(file, sz)
    output = readlines(file);
    output = str2num(output);
    output = reshape(output, flip(sz));
    output = permute(output, size(sz,2):-1:1);
end

