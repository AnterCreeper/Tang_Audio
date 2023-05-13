# Tang_Audio
Open Source Tang FPGA 9K Audio HAT  

### Attention! This Project is under CERN-OHL-P and Apache 2.0.
简单来说：  
1. 代码质量不保证， 出了问题我不管。我接受贡献。  
2. 你必须尊重他人的劳动成功，不能拿来改个名字说这不是我的。具体操作就是拷贝一份Apache License，CERN License并声明清楚与原项目的关系  
3. 在遵守上述二点的条件下，你爱干啥干啥  

### 工程说明：
1. test_audio_rtl: audio player rtl coding. the audio is stored in raw signed 16bit with big-endian.  

2. test_screen: simple screen player. the video is in YUV800, 128x64, 30fps.  

3. setclk.sh & setdac.sh: i2c configuration file.  

4. pcb: pcb project of this hat.  

#### 踩坑历史：
1. 重点注意连接器使用。包括检测脚悬空为耳机插入，接地为耳机断开；以及左右声道的接法。  
Must make clear how to use the audio connector. When the audio plug-in detect pin float, MAX9850 regards it connected. When it attached to the GND, the audio jack is detached.    

2. 耳机放大器输出的功率非常大（我确信这个音量有损健康），即使你把音量调到最低。如果是那些面向手机的，灵敏度比较高阻抗比较小的耳机，则需要串些电阻（大约300欧姆）来降低音量。当然如果你有大阻抗低灵敏度的那种耳机，比如森海塞尔HD 600, 300ohm阻抗和99dB的灵敏度，那么就不需要了，这个扩展板太适合不过了。 我没有这样的耳机，如果你有你可以试试，当然阻值大小需要你自己衡量，至少设置在三十欧姆。  
The volume of the audio is extremely high，which must harm your hearing, even when you set the volume to the minimum value. If you use some headsets designed for the mobile phone(about 32 ohms), then you need to add some resistors may about 300 ohms. If you have one Senhesier Headset which need a amp, this HAT is very suitable for them. I don't have something like that, but you can have a try to figure out how much you need to add， and at least  30 ohms.  

#### 一些浅显的看法：
1. 其实耳机不需要很高的功率。那么为什么我们探讨驱动能力？世界上并没有什么理想的绝对完美的东西，所以任何都是有限的。所以负载本身也会影响整个系统的H(s)。因此对于相同的负载来说，驱动能力越强，那么负载对于系统的影响越小。反过来，对于相同的系统，负载阻抗越大，干扰越小。这个对于运算放大器的增益也是一样的。  
因此耳机放大器是做什么的？他的目的就是起到隔离和驱动的作用，因为DAC本身的驱动能力非常差，所以放大器是必须的。（这个理解很简单，你可以考虑一个极端情况，比如你的负载是接近短路，很显然输出和理想是不一样的。这就是失真。）因此如果这个时候你再把一个32ohm的耳机插在DAC的输出（当然前提是DAC没有驱动电路，一些DAC自带线路驱动器）上，那么你会得到一个非常大的失真。不过除了上述愚蠢的做法，基本上绝大多数自带的放大器或者即使是线路驱动器都能很好地驱动耳机，应该没有那么糟糕的硅渣芯片。  
当然，根据上述描述，实际上阻抗越大的耳机音质反而更好，只是音量会比较低。那么坏处呢？坏处就是达到相同音量下所需的驱动能力的需求是不一样的，在更大的功率下达成相同的性能指标对于电子系统会带来更多复杂度和成本，也会更耗电（实际上应该从电源轨这个角度理解，有些芯片只能在3.3V下工作，但是有些可以在更低的电压比如1.8V下工作。芯片本身的功耗基本不值一提）。（比如我们考虑一个简单的场景。对于耳机来说，一个0.1%的THD+N是非常容易的。但是如果是1W，10W，或者是100W的功率下呢？:P  
至于平衡线，那就是玄学了，我不置评价。

2. 实际上，0.1%的失真对于大多数人类并不能听出来，现代的电子设备只要不是傻X行为素质都是足够的。所以换个耳机（比如一个木馒头）的效果更为显著。逃(  
