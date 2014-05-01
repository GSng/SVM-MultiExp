
% Sizes: 250, 200, 170, 150, 130
PZipf = sparse(810, 900);
PZipf(1:250,1:250) = 1;
PZipf(251:450,251:450) = 1;
PZipf(451:620,451:620) = 1;
PZipf(621:770,621:770) = 1;
PZipf(771:900,771:900) = 1;

[nx,ny] = size(PZipf);
rpm = randperm(nx);
PureZipf = PZipf(rpm,rpm);

noisePercent = 0.1;
numNoise = noisePercent * nnz(PureZipf);

NoisePart = sparse(size(PureZipf));

Inoise = [ceil(nx*rand(1,numNoise)); ceil(nx*rand(1,numNoise))];
for i = Inoise
  NoisePart(i(1), i(2)) = 1;
  NoisePart(i(2), i(1)) = 1;
end

NZipf = mod(PureZipf + NoisePart, 2);

rpm = randperm(nx);
NoisyZipf = NZipf(rpm,rpm);




% White Noise
WhiteNoise = sparse(100,100);
[nx,ny] = size(WhiteNoise);
numNoise = noisePercent * nx * ny;


Inoise = [ceil(nx*rand(1,numNoise)); ceil(nx*rand(1,numNoise))];
for i = Inoise
  WhiteNoise(i(1), i(2)) = 1;
  WhiteNoise(i(2), i(1)) = 1;
end


% Sanity check for outliers
CO = sparse(100,100);
CO(1:70,1:70)=1;
CO(71:100,71:100) = 1;
for i=1:30
	CO(i,70+i)=1;
end	
rpm = randperm(100);
CheckOutliers = CO(rpm,rpm);

% Sanity check for distances
DI = sparse(90,90);
DI(1:30,1:30)=1;
DI(31:60,31:60)=1;
DI(61:90,61:90)=1;
for i=1:30
	DI(i,30+i)=1;
	DI(i,61-i)=1;
	if(i<30)
		DI(i,31+i)=1;
		DI(31-i,31+i)=1;
	end	
	DI(30+i,60+i)=1;
end
rpm=randperm(90);
CheckDistances = DI(rpm,rpm);

save SynSymmetricGraphs PureZipf NoisyZipf WhiteNoise CheckOutliers CheckDistances;
