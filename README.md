# Rubber Band Library – iOS & macOS AVFoundation Example

This project demonstrates how to integrate the [Rubber Band Library](https://breakfastquay.com/rubberband/) into an iOS or macOS application using **AVFoundation**. It includes a working Objective-C example that loads an audio file, applies real-time pitch and time-stretching using Rubber Band, and plays back the processed audio.

---

## 🔧 Features

- ✅ Real-time audio pitch shifting
- ✅ Optional time-stretching
- ✅ Uses **Rubber Band v4.0.0** (R3 engine support)
- ✅ Formant preservation for natural voice quality
- ✅ Built with **AVAudioEngine** and **AVAudioPlayerNode**

---

## 📦 Requirements

- Xcode 14 or newer
- iOS 14+ or macOS 11+

---

## 🚀 Setup Instructions

1. Clone this repo

---

## 🧠 Key Concepts

- Rubber Band requires audio to be **de-interleaved** per channel
- Audio is processed in blocks and output is reassembled into buffers
- The `R3` engine (`OptionEngineFiner`) provides higher-quality pitch shifting
- `OptionFormantPreserved` maintains vocal character

---

## 🙌 Credits

- [Rubber Band Library](https://breakfastquay.com/rubberband/) by Particular Programs Ltd.
- Example developed by Jerry Seigle

---

## 📄 License

This example is for educational purposes and provided "as-is." For commercial use of the Rubber Band Library, you must obtain a license from the authors.

---
