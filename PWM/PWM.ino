#include <Bounce2.h>
#include <ADC.h>
#include <RingBuffer.h>

// Board Specifications //
const int samplingSpeed = ADC_HIGH_SPEED;

// Pin Declerations //
const int piezo = 33;
const int btn = 34;
const int mic = A9; // ADC0

// Variable Initilization //
Bounce debouncer = Bounce();
ADC *adc = new ADC();

int samples[20000];
int timestamps[20000];
int sampleIndex = 0;

unsigned int timeStart = 0;
unsigned int sampleTime = 15000;
//unsigned int sampleTime = 12000; // 2 meter range

bool sampling = false;
int serialIn = 0;

int value = 0;
int timestamp = 0;

int signalDelay = 0;
int burstLength = 0;

int costas_array[] = {2, 4, 8, 5, 10, 9, 7, 3, 6, 1};
int costas_index = 0;

void setup() {
  // Bouncer Object
  pinMode(btn, INPUT_PULLUP);
  debouncer.attach(btn);
  debouncer.interval(5);

  // ADC Object
  pinMode(mic, INPUT);
  adc->setAveraging(1); // set number of averages
  adc->setResolution(12); // set bits of resolution
  adc->setSamplingSpeed(samplingSpeed);
  adc->setConversionSpeed(samplingSpeed);
  
//  adc.setReference(ADC_REF_3V3, ADC_0);
  
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  pinMode(piezo, OUTPUT);

  Serial.begin(9600);

  adc->startContinuous(mic, ADC_0);
}


void loop() {

  if (sampling) {
    // Sampling
    if (micros() - timeStart < sampleTime) {
      value = (uint16_t)adc->analogReadContinuous(ADC_0);
      timestamp = micros() - timeStart;
      samples[sampleIndex] = value;
      timestamps[sampleIndex] = timestamp;
      sampleIndex++;
    } else {
      sampling = false;
//      noTone(piezo);

      // Send data over serial
      int i = 0;
      while(i < sampleIndex) {
        Serial.println(samples[i]*3.3/adc->getMaxValue(ADC_0), DEC);
        delayMicroseconds(1000);
        Serial.println(timestamps[i]);
        delayMicroseconds(1000);
        i++;
      }
      Serial.println("END");

      Serial.println(signalDelay);

      Serial.println(burstLength);

      Serial.println(sampleTime); // Length of the sample window

      Serial.println(sampleIndex); // Number of recorded samples
      
      sampleIndex = 0;
    }
    
  } else {
    // Not Sampling
    
    debouncer.update();

    if (Serial.available() > 0) {
      serialIn = Serial.read();
    }
  
    if (debouncer.rose() || serialIn == 's') {
      serialIn = 0;
      sampling = true;
      //adc->startContinuous(mic, ADC_0);
      timeStart = micros();

      // Output Burst Pattern

      // Single Pulse
//      tone(piezo, 40000);
//      delayMicroseconds(500);
//      noTone(piezo);

      // Linear Step
      for (int i = 0; i < 10; i++) {
        
        tone(piezo, 41000 - 200*i);
        delayMicroseconds(50);
      }
      noTone(piezo);

      // Costas Step
//      for (int i = 0; i < 10; i++) {
//        costas_index = costas_array[i];
//        tone(piezo, 39000 + 200*costas_index);
//        delayMicroseconds(50);
//      }
//      noTone(piezo);

      burstLength = micros() - timeStart;

      // Delay to avoid cross talk
      delayMicroseconds(500);
      
      signalDelay = micros() - timeStart;
    }
  }
}
