 function result=Conv2D(input, weights, bias)
    weights = flip(flip(weights,2),3);
    result = zeros(size(input, 1), size(input, 2), size(weights, 1));
    for i = 1:size(weights, 1)
        for c = 1:size(input, 3)
            result(:,:, i) = result(:,:, i) + (conv2(input(:,:,c), double(squeeze(weights(i,:,:,c))), 'same'));
        end
    end
    
    for i = 1:size(bias,2)
        result(:,:,i) = (result(:, :, i) + (double(bias(i))))/8;
    end
end