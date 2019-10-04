import time
from time import sleep
from picamera import PiCamera
import edgetpu.classification.engine
from io import BytesIO
import numpy as np


if __name__ == "__main__":
    print('Starting up')

    engine = edgetpu.classification.engine.ClassificationEngine('test_data/mobilenet_v2_1.0_224_quant_edgetpu.tflite')
    print('Edge TPU initialised')
    _, width, height, channels = engine.get_input_tensor_shape()
    with open('test_data/imagenet_labels.txt', 'r') as f:
        pairs = (l.strip().split(maxsplit=1) for l in f.readlines())
        labels = dict((int(k), v) for k, v in pairs)
    print('Labels read')
    with PiCamera(resolution='800x600', framerate=30, sensor_mode=2) as camera:
        print('Camera initialised')
        camera.start_preview()
        # Camera warm-up time
        sleep(2)

        print('Starting classify_image_stream')
        while True:
            stream = BytesIO()
            camera.capture(stream,
                           format='rgb',
                           use_video_port=True,
                           resize=(width, height))

            stream.truncate()
            stream.seek(0)
            input = np.frombuffer(stream.getvalue(), dtype=np.uint8)
            start_ms = time.time()
            results = engine.ClassifyWithInputTensor(input, top_k=1)
            elapsed_ms = time.time() - start_ms

            if results:
                print("%s %.2f\t%.2fms" % (labels[results[0][0]], results[0][1], elapsed_ms*1000.0))

            # reset stream for next frame
            stream.seek(0)
            stream.truncate()
            sleep(1)

