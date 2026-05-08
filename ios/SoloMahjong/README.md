# SoloMahjong iOS

Xcodeで開いて、自分のiPhoneにローカルインストールするためのSwiftUI版プロトタイプです。

## 目的

PWA版で見づらかった点を解消し、iPhone実機でストレスなく遊べる麻雀アプリの土台を作ります。

## 現在できること

- SwiftUIネイティブUI
- iPhone縦画面専用レイアウト
- CPU3人との簡易対局進行
- 配牌
- ツモ
- 牌選択
- 下部の大きな「捨てる」ボタン
- CPUの思考中表示
- 捨て牌表示
- 直前行動メッセージ
- 新しい局の開始

## まだ簡略化していること

- 完全な役判定
- 完全な点数計算
- リーチ、鳴き、カンの完全実装
- 高度なCPU思考

まずはiPhoneでの見やすさと操作感を優先したプロトタイプです。

## Xcodeで開く

1. Macでこのリポジトリをpullします。
2. `ios/SoloMahjong/SoloMahjong.xcodeproj` をXcodeで開きます。
3. `SoloMahjong` targetを選びます。
4. `Signing & Capabilities` で自分のTeamを選びます。
5. Bundle Identifierが重複する場合は変更します。
6. iPhoneを接続してRunします。

## 推奨Bundle Identifier

```text
com.stsuchiya.solomahjong
```
