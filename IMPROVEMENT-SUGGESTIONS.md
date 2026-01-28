# Waveform Display Improvement Suggestions

The current waveform display in `gui/viewfinder.scd` is inefficient because it writes audio buffers to temporary files on disk and then reads them back into the GUI. This introduces disk I/O latency, especially for newly recorded or edited audio.

Here are three suggestions for improvement, ranging from a simple fix to a more advanced, professional solution.

---

### Suggestion 1: Easy Fix - Draw from Memory Instead of Disk

The simplest way to improve this is to stop using temporary files and transfer the audio data directly from the server's memory to the GUI.

**How:**
Instead of writing a `.wav` file, use `buffer.loadToFloatArray`. This function asynchronously loads the buffer's sample data into an array. You can then use `sfv.loadCollection(theArray)` to draw it, or create an in-memory `SoundFile` to load. This avoids all disk I/O.

**Example:**
```supercollider
// Replace this...
// newBuffer.write(tempPath, "WAV", "int16");
// server.sync;
// soundFile.openRead(tempPath);

// With this...
fork {
    newBuffer.loadToFloatArray(action: { |array|
        {
            sfv.loadCollection(array, numChannels: newBuffer.numChannels);
            sfv.refresh;
        }.defer;
    });
};
```

*   **Pro:** Easy to implement and completely removes the disk-writing bottleneck.
*   **Con:** For very long buffers (many minutes), transferring the entire file into the GUI's memory might still be slow.

---

### Suggestion 2: Better Fix - Downsample the Waveform Data

A waveform view doesn't need all 48,000 samples per second to be drawn. You can create a "summary" of the waveform that is much smaller and faster to draw.

**How:**
Before loading the data into the view, process the `FloatArray` from Suggestion 1. For each horizontal pixel of the display, find the minimum and maximum sample values in the corresponding audio chunk. Create a new array containing just these min/max pairs. Drawing this summary array results in a visually identical waveform that uses a fraction of the data.

*   **Pro:** Extremely fast and memory-efficient, even for very long files.
*   **Con:** Requires writing a custom function to perform the downsampling calculation.

---

### Suggestion 3: Professional Solution - On-Demand Custom Drawing

This is how professional DAWs handle it. Instead of `SoundFileView`, you would use a custom `UserView` and draw the waveform manually with the `Pen` class.

**How:**
The view's drawing function would only request the *currently visible* segment of the audio buffer from the server using `buffer.getn`. When you scroll or zoom, the view requests different segments of data as needed.

*   **Pro:** The most performant and scalable solution. It can handle hours of audio with virtually no memory overhead, as only the visible portion is ever loaded.
*   **Con:** This is the most complex solution to implement, as you have to manually manage all the drawing, scrolling, and data-requesting logic.
