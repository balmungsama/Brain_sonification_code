COUNT = argv();
COUNT = COUNT{1};

timecourses = dir(['../ROI_tcourses/t_*' COUNT '.txt']);
dur_note = 0.1;
freqs = 2000:2000:16000;

for course = 1:length(timecourses)
  filename = (timecourses(course).name);
  filename = strsplit(filename, '.');
  filename = filename{1};
  
  amps = load(['../ROI_tcourses/' timecourses(course).name]);
  
  %%%%%%%%%%%%%%%%%%%%%
  %%% MAKING MUSIC%%%%%
  %%%%%%%%%%%%%%%%%%%%%
  
  duration = dur_note * length(amps);
  fs = 44100;                    % sampling rate
  T = 1/fs;                      % sampling period
  t = [0:T:duration];                % time vector
  
  amps2 = 1:(fs * length(amps) * dur_note);
  
  for amp = 1:length(amps)
    amps2( ((amp-1)* fs * dur_note)+1:(fs*amp*dur_note) ) = repmat(amps(amp), fs*dur_note ,1);
  end
  
  amps2 = amps2;
  
  f1 = freqs(course);                       % frequency in Hertz
  omega1 = f1 ;%*2*pi;              % angular frequency in radians
  
  phi = 2*pi*0.75;               % arbitrary phase offset = 3/4 cycle
  x1 = cos(omega1*t + phi);      % sinusoidal signal, amplitude = 1
  
%   plot(t, x1);                   % plot the signal
%   xlabel('Time (seconds)');
%   ylabel('x1');
%   title('Simple Sinusoid');
%   sound(x1(1:length(x1)-1) .* amps2, fs);             % play the signal
  audiowrite(['../ROI_tcourses/sound_files/' filename '.wav'], x1(1:length(x1)-1) .* amps2, fs)
  
  disp(['         ' filename ' in ' num2str(f1) ' Hz is ready.']);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
end