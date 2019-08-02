debug:
	dub --config=debug --arch=x86_64

release:
	dub --config=release --arch=x86_64 --build=release

release-x86:
	dub build --config=release --arch=x86 --build=release