# PCM8A 改造版

PCM8A version 1.02(philly氏作)の改造版です。

無保証です。
十分なテストを行っていないので、不具合があるかもしれません。


## 変更点

* 8bit PCMを音量$8、$c、$7f-$81、$89-$8aで再生するとアドレスエラーが発生する不具合を修正しました。
* I/Oアドレスを`$FFxxxxxx`から`$00xxxxxx`に変更し、ハイメモリ環境でも動作するようにしました。
  * `$FFxxxxxx`になっていた理由は下記を参照してください。
    * https://twitter.com/Hau_oli/status/1639047191246548992
    * https://twitter.com/Hau_oli/status/1639048580144168961


## Build

PCやネット上での取り扱いを用意にするために、src/内のファイルはUTF-8で記述されています。
X680x0上でビルドする際には、UTF-8からShift_JISへの変換が必要です。

### src2buildを使用する場合

必要ツール: [src2build](https://github.com/kg68k/src2build)

srcディレクトリのある場所で以下のコマンドを実行します。
```
src2build src
make -C build
```

### その他の方法

src/内のファイルを適当なツールで適宜Shift_JISに変換して別のディレクトリに保存し、
ディレクトリ内で`make`を実行してください。  
UTF-8のままでは正しくビルドできません。


## Author

原著作者: philly 氏

改造版作者: TcbnErik / https://github.com/kg68k/pcm8a

