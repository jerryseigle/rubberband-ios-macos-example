#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#include "rubberband/RubberBandStretcher.h" // Include the Rubber Band library for pitch and time manipulation

using namespace RubberBand; // Use RubberBand namespace to access its classes directly

@interface ViewController ()
@property AVAudioEngine *engine;            // Audio engine to handle audio routing and playback
@property AVAudioPlayerNode *player;       // Audio node used to play processed audio buffers
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad]; // Standard iOS lifecycle call to parent viewDidLoad

    /**
     * SECTION 1: Load the audio file from the app bundle
     * - Loads "JesusWill.mp3"
     * - Reads it into a PCM audio buffer for processing
     */
    
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"JesusWill" withExtension:@"mp3"]; // Locate the audio file in the app bundle
    
    AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:nil]; // Open the audio file for reading
    
    AVAudioFormat *format = [audioFile processingFormat]; // Get the format info (sample rate, channels)
    AVAudioFrameCount frameCount = (AVAudioFrameCount)audioFile.length; // Get total number of audio frames in the file
    
    AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:frameCount]; // Create a buffer large enough to hold all audio
    [audioFile readIntoBuffer:buffer error:nil]; // Read the file’s data into the buffer

    /**
     * SECTION 2: Configure the RubberBandStretcher
     * - Initializes RubberBand with desired options
     * - Sets time and pitch manipulation parameters
     */
    
    int sampleRate = (int)format.sampleRate; // Store sample rate
    int channels = (int)format.channelCount; // Store channel count (mono = 1, stereo = 2, etc.)
    
    RubberBandStretcher stretcher(sampleRate, channels,
        RubberBandStretcher::OptionProcessRealTime |        // Use real-time mode for streaming input
        RubberBandStretcher::OptionEngineFiner |            // Use high-quality R3 engine
        RubberBandStretcher::OptionThreadingAuto |          // Allow engine to use threads as needed
        RubberBandStretcher::OptionWindowStandard |         // Standard window size for FFT processing
        RubberBandStretcher::OptionPitchHighQuality |       // Favor pitch quality over CPU efficiency
        RubberBandStretcher::OptionChannelsTogether);       // Maintain stereo balance and mono compatibility
    
    stretcher.setTimeRatio(1); // This should be changed from 0 to a real ratio (e.g., 1.0 for no change)
    stretcher.setPitchScale(1.28); // Raise the pitch by ~28% (about +4 semitones)
    stretcher.setFormantOption(RubberBandStretcher::OptionFormantPreserved); // Preserve vocal character during pitch shift
    stretcher.setTransientsOption(RubberBandStretcher::OptionTransientsSmooth);

    /**
     * SECTION 3: Process the audio buffer in chunks
     * - Passes audio into RubberBand
     * - Retrieves processed output
     * - Stores it in a raw byte buffer
     */
    
    int totalFrames = (int)buffer.frameLength; // Total frames in the audio buffer
    int blockSize = 512; // Number of frames per block to process
    NSMutableData *processedData = [NSMutableData data]; // Container to hold all output audio
    
    float **input = new float*[channels]; // Allocate array of float pointers, one per channel
    
    for (int i = 0; i < totalFrames; i += blockSize) { // Loop through audio in blocks
        int count = MIN(blockSize, totalFrames - i); // Get actual block size (may be smaller at the end)
        
        for (int ch = 0; ch < channels; ++ch) {
            input[ch] = (float *)buffer.floatChannelData[ch] + i; // Set input pointer to current chunk
        }
        
        stretcher.process(input, count, (i + count >= totalFrames)); // Send chunk to RubberBand for processing
        
        int avail = 0;
        while ((avail = stretcher.available()) > 0) { // While there's processed output available...
            float **out = new float*[channels]; // Create output buffer
            
            for (int ch = 0; ch < channels; ++ch) {
                out[ch] = new float[avail]; // Allocate output memory for each channel
            }
            
            stretcher.retrieve(out, avail); // Retrieve processed audio into output buffer
            
            for (int j = 0; j < avail; ++j) { // Loop over frames
                for (int ch = 0; ch < channels; ++ch) { // Loop over channels
                    float sample = out[ch][j]; // Read each sample
                    [processedData appendBytes:&sample length:sizeof(float)]; // Append to processed output
                }
            }
            
            for (int ch = 0; ch < channels; ++ch) delete[] out[ch]; // Free memory for each channel
            delete[] out; // Free output buffer pointer array
        }
    }
    delete[] input; // Clean up input pointer array

    /**
     * SECTION 4: Convert raw processed data into an AVAudioPCMBuffer
     * - Prepares it for playback through AVAudioEngine
     */
    
    AVAudioFormat *outFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:sampleRate channels:channels interleaved:NO]; // Define format for output buffer
    
    NSUInteger processedFrames = processedData.length / (sizeof(float) * channels); // Calculate number of frames in output buffer
    
    AVAudioPCMBuffer *outBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:outFormat frameCapacity:(AVAudioFrameCount)processedFrames]; // Create output buffer
    outBuffer.frameLength = (AVAudioFrameCount)processedFrames; // Set actual number of frames in the buffer
    
    float *dataPtr = (float *)processedData.bytes; // Get raw pointer to float data
    
    for (int ch = 0; ch < channels; ++ch) {
        float *chPtr = outBuffer.floatChannelData[ch]; // Get channel-specific buffer
        
        for (NSUInteger i = 0; i < processedFrames; ++i) {
            chPtr[i] = dataPtr[i * channels + ch]; // Convert interleaved samples into channel-separated buffer
        }
    }

    /**
     * SECTION 5: Set up AVAudioEngine and play processed buffer
     * - Connects player to engine
     * - Schedules buffer for playback
     */
    
    self.engine = [[AVAudioEngine alloc] init]; // Initialize the audio engine
    self.player = [[AVAudioPlayerNode alloc] init]; // Create player node to handle playback
    
    [self.engine attachNode:self.player]; // Add player to audio engine graph
    [self.engine connect:self.player to:self.engine.mainMixerNode format:outFormat]; // Connect player to output with correct format
    
    [self.engine startAndReturnError:nil]; // Start audio engine
    
    [self.player scheduleBuffer:outBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil]; // Schedule processed audio to loop
    
    [self.player play]; // Begin playback
}

@end
