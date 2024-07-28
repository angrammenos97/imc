clear
%% First layer
image    = ImportData('image.txt', [32 32 3]);
weights1 = ImportData('weights1.txt', [16 3 3 3]);
bias1    = ImportData('bias1.txt', [1 16]);
output1  = ImportData('output1.txt', [32 32 16]);

result = Conv2D(image, weights1, bias1);
res1 = Relu(result);

%% Second layer
weights2 = ImportData('weights2.txt', [16 3 3 16]);
bias2    = ImportData('bias2.txt', [1 16]);
output2  = ImportData('output2.txt', [32 32 16]);

result = Conv2D(res1, weights2, bias2);
res2 = Relu(result);

%% Third layer
weights3 = ImportData('weights3.txt', [16 3 3 16]);
bias3    = ImportData('bias3.txt', [1 16]);
output3  = ImportData('output3.txt', [32 32 16]);

result = Conv2D(res2, weights3, bias3);
res3 = int8(fix(result));

%% Forth layer
output4  = ImportData('output4.txt', [32 32 16]);
result = double(res1) + double(res3);
res4 = Relu(result);