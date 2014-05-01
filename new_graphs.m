
% Sizes: row => 300, 200, 140, 100, 70
%        col => 250, 200, 170, 150, 130
PZipf = sparse(810, 900);
PZipf(1:300,1:250) = 1;
PZipf(301:500,251:450) = 1;
PZipf(501:640,451:620) = 1;
PZipf(641:740,621:770) = 1;
PZipf(741:810,771:900) = 1;

[nx,ny] = size(PZipf);
PureZipf = PZipf(randperm(nx),randperm(ny));

noisePercent = 0.1;
numNoise = noisePercent * nnz(PureZipf);

NoisePart = sparse(size(PureZipf));
Inoise = [ceil(nx*rand(1,numNoise)); ceil(ny*rand(1,numNoise))];
for i = Inoise
  NoisePart(i(1), i(2)) = 1;
end

NZipf = mod(PureZipf + NoisePart, 2);

NoisyZipf = NZipf(randperm(nx),randperm(ny));


% The "customer-product" graph
% Sizes: cust prod
%        100    10
%        70     20
%        50     25
%        40     28
%        35     30

CP = sparse(295,30);
CP(1:100,1:10) = 1;
CP(101:170,1:20) = 1;
CP(171:220,1:25) = 1;
CP(221:260,1:28) = 1;
CP(261:295,1:30) = 1;

[nx,ny] = size(CP);
PureCP = CP(randperm(nx),randperm(ny));

numNoise = noisePercent * nnz(CP);
NoisePart = sparse(size(CP));
Inoise = [ceil(nx*rand(1,numNoise)); ceil(ny*rand(1,numNoise))];
for i = Inoise
  NoisePart(i(1), i(2)) = 1;
end

NCP = mod(CP + NoisePart, 2);
NoisyCP = NCP(randperm(nx),randperm(ny));



% White Noise
WhiteNoise = sparse(100,100);
[nx,ny] = size(WhiteNoise);
numNoise = noisePercent * nx * ny;

Inoise = [ceil(nx*rand(1,numNoise)); ceil(ny*rand(1,numNoise))];
for i = Inoise
  WhiteNoise(i(1), i(2)) = 1;
end


save SynGraphs PureZipf NoisyZipf PureCP NoisyCP WhiteNoise;
