import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:path/path.dart' as p;

/// Brand icon: primary blue background + white "HL".
///
/// Run from repo root:
///   cd app && dart run tool/generate_icons.dart
final ColorRgb8 _background = ColorRgb8(0, 95, 184);
final ColorRgb8 _foreground = ColorRgb8(255, 255, 255);
const String _label = 'HL';
const int _renderSize = 256;

void main() {
  // Run from `app/` (see file header).
  final String appRoot = Directory.current.path;

  _writeAndroidIcons(appRoot);
  _writeIosIcons(appRoot);
  _writeMacosIcons(appRoot);
  _writeWindowsIcon(appRoot);

  stdout.writeln('Icons written under $appRoot');
}

Image _renderIcon(int size) {
  final Image base = Image(width: _renderSize, height: _renderSize);
  fill(base, color: _background);

  drawString(base, _label, font: arial48, color: _foreground);

  if (size == _renderSize) {
    return base;
  }
  return copyResize(
    base,
    width: size,
    height: size,
    interpolation: Interpolation.cubic,
  );
}

void _writePng(String path, int size) {
  final File file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(_renderIcon(size)));
}

void _writeAndroidIcons(String appRoot) {
  const Map<String, int> densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final MapEntry(:key, :value) in densities.entries) {
    _writePng(
      p.join(appRoot, 'android', 'app', 'src', 'main', 'res', key, 'ic_launcher.png'),
      value,
    );
  }
}

void _writeIosIcons(String appRoot) {
  const Map<String, int> icons = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  final String dir = p.join(
    appRoot,
    'ios',
    'Runner',
    'Assets.xcassets',
    'AppIcon.appiconset',
  );
  for (final MapEntry(:key, :value) in icons.entries) {
    _writePng(p.join(dir, key), value);
  }
}

void _writeMacosIcons(String appRoot) {
  const Map<String, int> icons = {
    'app_icon_16.png': 16,
    'app_icon_32.png': 32,
    'app_icon_64.png': 64,
    'app_icon_128.png': 128,
    'app_icon_256.png': 256,
    'app_icon_512.png': 512,
    'app_icon_1024.png': 1024,
  };

  final String dir = p.join(
    appRoot,
    'macos',
    'Runner',
    'Assets.xcassets',
    'AppIcon.appiconset',
  );
  for (final MapEntry(:key, :value) in icons.entries) {
    _writePng(p.join(dir, key), value);
  }
}

void _writeWindowsIcon(String appRoot) {
  final String path = p.join(appRoot, 'windows', 'runner', 'resources', 'app_icon.ico');
  File(path).writeAsBytesSync(_encodePngIco(_renderIcon(256)));
}

/// Windows Vista+ ICO with a single embedded PNG payload.
Uint8List _encodePngIco(Image image) {
  final Uint8List png = Uint8List.fromList(encodePng(image));
  final BytesBuilder builder = BytesBuilder();

  builder
    ..add([0, 0, 1, 0, 1, 0]) // ICONDIR
    ..add([
      image.width & 0xFF,
      image.height & 0xFF,
      0,
      0,
      1,
      0,
      32,
      0,
      png.length & 0xFF,
      (png.length >> 8) & 0xFF,
      (png.length >> 16) & 0xFF,
      (png.length >> 24) & 0xFF,
      22,
      0,
      0,
      0,
    ])
    ..add(png);

  return builder.toBytes();
}
