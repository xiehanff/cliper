.PHONY: get clean analyze run-windows build-windows build-installer-windows package-windows

FLUTTER := fvm flutter

get:
	$(FLUTTER) pub get

clean:
	$(FLUTTER) clean

analyze:
	$(FLUTTER) analyze

run-windows:
	$(FLUTTER) run -d windows

build-windows:
	$(FLUTTER) build windows --release

build-installer-windows:
	powershell -ExecutionPolicy Bypass -File .\windows\installer\build_installer.ps1

package-windows:
	powershell -ExecutionPolicy Bypass -File .\windows\installer\build_installer.ps1
