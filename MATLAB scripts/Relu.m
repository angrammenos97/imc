function result=Relu(input)
    result = min(input, 15);
    result = uint8(max(result, 0));
end