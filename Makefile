build-container:
	docker build -t tensorflow-cpu-py3.6.6 --build-arg PYTHON_VER="3.6.6" .
build:
	docker run -it --rm \
		-v `pwd`/scripts:/root/scripts \
		-v `pwd`/tensorflow:/root/tensorflow \
		-v `pwd`/out:/root/out \
		tensorflow-cpu-py3.6.6 \
		/root/scripts/build.sh
clean:
	rm -rf tensorflow/* tensorflow/.*
list-pyversion:
	docker run -it --rm \
		tensorflow-cpu-py3.6.6 \
		/root/.pyenv/bin/pyenv install --list
