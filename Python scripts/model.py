from keras.datasets import cifar10
from keras.models import load_model
from keras.utils import custom_object_scope
from qkeras import QConv2D, QActivation, QDense
from keras import Model
import numpy as np
import tensorflow as tf
# from matplotlib import pyplot as plt

(_, _), (test_images_original, test_labels) = cifar10.load_data()
# plt.imshow(test_images[0])
# plt.show()

# Quantize the input images
test_images = np.floor(test_images_original / 16).astype('float32') / 16
# qbits = 4
# integer = 2 ** qbits - 1
# scale = 1 / integer
# test_images = np.round(test_images * integer) * scale
# test_images_mean = np.mean(test_images, axis=0)
# test_images -= test_images_mean

class myQConv2D(QConv2D):
    def __init__(self, **kwargs):
        super(myQConv2D, self).__init__(**kwargs)
        self.kernel_quantizer_internal.alpha = None     # stop auto-scaling of the weights

    def get_qkernel(self):
        return self.get_quantizers()[0](self.kernel)
    
    def get_qbias(self):
        return self.get_quantizers()[1](self.bias)

with custom_object_scope({'myQConv2D': myQConv2D}):
    with custom_object_scope({'QConv2D': myQConv2D}):
        with custom_object_scope({'QActivation': QActivation}):
            with custom_object_scope({'QDense': QDense}):
                # model = load_model('/data/asic_u/tempo/ana42838/pulp_temp/python_model/model.h5')
                # model = load_model('/data/asic_u/tempo/ana42838/pulp_temp/python_model/cifartrial.h5')
                # model = load_model('/data/asic_u/tempo/ana42838/pulp_temp/python_model/cifartrial_b5.h5')
                # model = load_model('/data/asic_u/tempo/ana42838/pulp_temp/python_model/cifartrial_b8.h5')
                # model = load_model('/data/asic_u/tempo/ana42838/pulp_temp/python_model/cifartrial_b8_none.h5')
                model = load_model('/data/asic_u/tempo/ana42838/pulp_temp/python_model/cifartrial_b8_none_input.h5')
                model.summary()

# layer_name = 'q_conv2d'
# layer_name = 'q_activation'
# layer_name = 'q_conv2d_1'
layer_name = 'q_activation_1'
# layer_name = 'q_conv2d_2'
# layer_name = 'add'
# layer_name = 'q_activation_2'
intermediate_layer_model = Model(inputs=model.input, outputs=model.get_layer(layer_name).output)
intermediate_output = intermediate_layer_model(test_images[2:3])

conv_layer_name = 'q_conv2d'
# conv_layer_name = 'q_conv2d_1'
# conv_layer_name = 'q_conv2d_2'
first_layer = model.get_layer(conv_layer_name)
first_weights = first_layer.get_qkernel().numpy() #kernel.numpy()
first_biases = first_layer.get_qbias().numpy()
first_output = intermediate_output[0].numpy()

we = np.moveaxis(first_weights, -1, 0)
# we = np.flip(np.flip(we, 1), 2)

# (test_images_original[0]).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/image.txt', sep=',', format='%d')
# (test_images_original[0]/16).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/image.txt', sep=',', format='%d')
(test_images[2]*16).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/image.txt', sep=',', format='%d')
# (first_weights*8).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/weights.txt', sep=',', format='%d')
(we*8).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/weights.txt', sep=',', format='%d')
# (we).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/weights.txt', sep=',', format='%f')
# (first_biases*32868).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/bias.txt', sep=',', format='%d')
(first_biases*128).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/bias.txt', sep=',', format='%d')
# (first_biases*16).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/bias.txt', sep=',', format='%d')
# (first_biases).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/bias.txt', sep=',', format='%f')
(first_output*16).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/output.txt', sep=',', format='%d')
# (first_output).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/output.txt', sep=',', format='%f')

# (test_images_mean).tofile('/data/asic_u/tempo/ana42838/pulp_temp/python_model/image_mean.txt', sep=',', format='%f')


print("Image shape = ", end='')
print(test_images[0].shape)
print("Weights shape = ", end='')
print(we.shape)
print("Bias shape = ", end='')
print(first_biases.shape)
print("Output shape = ", end='')
print(first_output.shape)