function plot_binary(A, isSelfGraph, row_mask, col_mask)
% PLOT_BINARY plot a binary matrix (optionally masking out select
%   rows and columns).  Values of A are assumed to be 0/1.
%
% $Id: plot_binary.m,v 1.6 2004/04/28 18:59:11 deepay Exp $

if nargin < 4, col_mask = false(size(A,2), 1); end
if nargin < 3, row_mask = false(size(A,1), 1); end
if nargin < 2, isSelfGraph = false; end
  
Atmp = A + 1;
Atmp(row_mask,col_mask) = 3;
image(Atmp);
axis square;
cmap=diag([1 0 0.6])*ones(3,3);  % colors for: (zero, masked, one)
cmap(3,1) = 0.7;
colormap(cmap);

if(isSelfGraph)
	ylabel('Node Groups');
	xlabel('Node Groups');
else
	ylabel('Row Clusters');
	xlabel('Column Clusters');
end

% $Log: plot_binary.m,v $
% Revision 1.6  2004/04/28 18:59:11  deepay
% working with new plot_binary
%
% Revision 1.5  2004/04/02 15:14:21  deepay
% Should mostly work for self-graphs
%
% Revision 1.4  2004/02/26 16:29:17  deepay
% *** empty log message ***
%
% Revision 1.3  2004/02/21 04:31:03  deepay
% *** empty log message ***
%
% Revision 1.2  2004/02/04 23:56:17  spapadim
% Misc touchups
%

