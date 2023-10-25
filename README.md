# Tang_Audio
Open Source Tang FPGA 9K Audio HAT  

### Attention! This Project is under CERN-OHL-P and Apache 2.0.

### 工程说明：
1. test_audio_rtl: audio player rtl coding. the audio is stored in raw signed 16bit with little-endian.  

2. test_screen(deprecated): simple screen player. the video is in YUV800, 128x64, 30fps.  

3. setclk.sh & setdac.sh: i2c configuration file.  

4. pcb: pcb project of this hat.  

5. track_maker: tools to create audio track.  

#### 历史：  

rev A: 初始版本，包含OLED，PLL，DMIC，DAC  
rev B: 修复连接器插入识别问题，更换音频连接器，移除OLED，添加USB功能，按钮数量减为两个并增加一个滑动开关  

#### 未来：  
rev B.1: 修复USB插座EMI问题
