# Copyright 2017 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import argparse
import os
import glob
import time

import numpy as np
import tensorflow as tf


def load_graph(model_file):
  graph = tf.Graph()
  graph_def = tf.GraphDef()

  with open(model_file, "rb") as f:
    graph_def.ParseFromString(f.read())
  with graph.as_default():
    tf.import_graph_def(graph_def)

  return graph


def read_tensor_from_image_file(file_name,
                                input_height=299,
                                input_width=299,
                                input_mean=0,
                                input_std=255):
  input_name = "file_reader"
  output_name = "normalized"
  file_reader = tf.read_file(file_name, input_name)
  if file_name.endswith(".png"):
    image_reader = tf.image.decode_png(
        file_reader, channels=3, name="png_reader")
  elif file_name.endswith(".gif"):
    image_reader = tf.squeeze(
        tf.image.decode_gif(file_reader, name="gif_reader"))
  elif file_name.endswith(".bmp"):
    image_reader = tf.image.decode_bmp(file_reader, name="bmp_reader")
  else:
    image_reader = tf.image.decode_jpeg(
        file_reader, channels=3, name="jpeg_reader")
  float_caster = tf.cast(image_reader, tf.float32)
  dims_expander = tf.expand_dims(float_caster, 0)
  resized = tf.image.resize_bilinear(dims_expander, [input_height, input_width])
  normalized = tf.divide(tf.subtract(resized, [input_mean]), [input_std])
  sess = tf.Session()
  result = sess.run(normalized)

  return result


def load_labels(label_file):
  label = []
  proto_as_ascii_lines = tf.gfile.GFile(label_file).readlines()
  for l in proto_as_ascii_lines:
    label.append(l.rstrip())
  return label


if __name__ == "__main__":
    file_name = "tensorflow/examples/label_image/data/grace_hopper.jpg"
    model_file = "/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/models/output_graph.pb"
    label_file = "/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/models/output_labels.txt"
    input_height = 299
    input_width = 299
    input_mean = 0
    input_std = 255
    input_layer = "Placeholder"
    output_layer = "final_result"

    parser = argparse.ArgumentParser()
    parser.add_argument("--image", help="image to be processed")
    parser.add_argument("--graph", help="graph/model to be executed")
    parser.add_argument("--labels", help="name of file containing labels")
    parser.add_argument("--input_height", type=int, help="input height")
    parser.add_argument("--input_width", type=int, help="input width")
    parser.add_argument("--input_mean", type=int, help="input mean")
    parser.add_argument("--input_std", type=int, help="input std")
    parser.add_argument("--input_layer", help="name of input layer")
    parser.add_argument("--output_layer", help="name of output layer")
    args = parser.parse_args()

    if args.graph:
        model_file = args.graph
    if args.image:
        file_name = args.image
    if args.labels:
        label_file = args.labels
    if args.input_height:
        input_height = args.input_height
    if args.input_width:
        input_width = args.input_width
    if args.input_mean:
        input_mean = args.input_mean
    if args.input_std:
        input_std = args.input_std
    if args.input_layer:
        input_layer = args.input_layer
    if args.output_layer:
        output_layer = args.output_layer

    #graph = load_graph(model_file)

    os.chdir("/home/ebjohnson5/Data/tmp_photos2")

    i = 0
    all_files = glob.glob('*.jpg')
    all_files.extend(glob.glob('*.JPG'))
    totalNumber = len(all_files)
    print("total number of images is:", totalNumber)
    labels = load_labels(label_file)
    iteration = 0
    step_size = 100
    start_range = list(range(1, totalNumber, step_size))
    end_range = list(range(step_size, totalNumber, step_size))
    end_range.append(totalNumber)

    n_restarts = len(start_range)
    restart_indices = list(range(0, n_restarts-1, 1))

    for restart_index in restart_indices:
        start_ind = start_range[restart_index]
        end_ind = end_range[restart_index]
        files = all_files[start_ind:end_ind]
        graph = load_graph(model_file)
        with tf.Session(graph=graph) as sess:
            for file_name in files:
                iteration = iteration + 1
                tic = time.time()
                print(file_name)
                t = read_tensor_from_image_file(
                    file_name,
                    input_height=input_height,
                    input_width=input_width,
                    input_mean=input_mean,
                    input_std=input_std)

                input_name = "import/" + input_layer
                output_name = "import/" + output_layer
                input_operation = graph.get_operation_by_name(input_name)
                output_operation = graph.get_operation_by_name(output_name)
                results = sess.run(output_operation.outputs[0], {
                    input_operation.outputs[0]: t
                })
                results = np.squeeze(results)
                 #sess.close()
                top_k = results.argsort()[-5:][::-1]

                outfile = '/home/ebjohnson5/Data/tmp/' + file_name + '.csv'
                #outfile = '/home/ebjohnson5/Dropbox/pkg.data/curb_appeal/numpy/test.csv'
                np.savetxt(outfile, results, delimiter=",")
                #np.save(outfile, results)
                for i in top_k:
                    print(file_name, labels[i], results[i])


                toc = time.time()-tic
                print(iteration, 'of', totalNumber, 'in', toc)
                time_remaining = (totalNumber-iteration) * toc
                print('Hours remaining', time_remaining/3600)
        sess.close()
        tf.reset_default_graph()