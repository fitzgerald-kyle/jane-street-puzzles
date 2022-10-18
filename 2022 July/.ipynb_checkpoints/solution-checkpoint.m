%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOCCER BALL:
% We take a first-step analysis approach. We designate 'uij' as the
% expected time to reach j from i, where we have used symmetry to let
% an index represent the *shortest distance* from our arbitrary start
% point.
%
% u00 = 1 + u10
% u10 = 1 + 1/3*0 + 2/3*u20
% u20 = 1 + 1/3*u10 + 1/3*u20 + 1/3*u30
% u30 = 1 + 1/3*u20 + 1/3*u30 + 1/3*u40 
% u40 = 1 + 2/3*u30 + 1/3*u50
% u50 = 1 + u40
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% coefficient matrix from above system
A = [1   -1    0    0    0    0;
     0    1 -2/3    0    0    0;
     0 -1/3  2/3 -1/3    0    0;
     0    0 -1/3  2/3 -1/3    0;
     0    0    0 -2/3    1 -1/3;
     0    0    0    0   -1    1];
 
% RHS from above system
b = [1; 1; 1; 1; 1; 1];

times2return2zero = round(A \ b, 7); % = [20; 19; 27; 32; 34; 35]

soccerExpReturnTime = times2return2zero(1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% KITCHEN FLOOR:
% Online resources indicate that the honeycomb lattice is recurrent,
% which leads me to conclude that our lattice is also recurrent, meaning
% that any state is guaranteed to be revisited. This means that we can
% determine the probability of taking a k-length closed path (from an
% arbitrary starting point, by symmetry) for all k no more than
% 'soccerExpReturnTime', add these together, and subtract from 1 to get our
% answer.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
maxSteps = soccerExpReturnTime;  % maximum allowable random walk steps

% generate a kitchen floor adjacency grid that is large enough
rows = maxSteps+1; 
cols = rows;
adjacencies = zeros(rows*cols, rows*cols);

% Generate the adjacency matrix, referencing the picture on 
% https://www.janestreet.com/puzzles/andys-morning-stroll.png
for i = 1:rows
    for j = 1:cols
        idx = (i-1)*cols + j;

        try
            adjacencies(idx, idx-(-1)^i*(-1)^j*cols) = 1;
        catch
        end
        
        if j ~= 1
            adjacencies(idx, idx-1) = 1;
        end
        
        if j ~= cols
            adjacencies(idx, idx+1) = 1;
        end
    end
end

adjacencies = adjacencies(1:rows*cols, 1:rows*cols);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: Below we distinguish between 'k-walks' and 'k-paths'. A 'k-walk'
% ends at the start point after k steps BUT may have already crossed the 
% start point in less than k steps; a 'k-path' returns to the start point
% for the first time after k steps.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

totPaths = 0;  % count all k-length paths, k <= maxSteps
totProb = 0;  % weight k-length paths by their respective probabilities

midIdx = round(rows*cols/2);  % use a reference index in the middle of the board
totkWalks = zeros(maxSteps,1);  % store closed k-walk totals

% Note that the entries of 'adjacencies^k' represent closed k-WALK totals,
% not k-paths
for k = 1:maxSteps
    kStepWalks = adjacencies^k;
    totkWalks(k) = kStepWalks(midIdx,midIdx);
end

totkPaths = totkWalks;  % store closed k-path totals
% store a count of k-walks to subtract from k-walk totals to get k-paths
walks2subtract = zeros(maxSteps,1);

% For a k-path count, we need to subtract all identical-object
% permutations of the integer partitions of k. For example, to obtain all
% 4-paths, we need to subtract 4-walks composed of two 2-paths.
%
% References:
% https://math.stackexchange.com/questions/3638928/how-to-calculate-the-
% number-of-closed-walks-of-length-5-that-dont-pass-through
% https://www.cs.sfu.ca/~ggbaker/zju/math/perm-comb-more.html
for k = 1:maxSteps
    plist = partitions(k);
    dim = size(plist);
    for p = 1:dim(1)-1  % ignore the final partition
        identicalPerms = int64( factorial(sum(plist(p,:))) ...
                            / prod(factorial(plist(p,:))) );

        walks2subtract(k) = walks2subtract(k) + ...
            prod( totkPaths(1:k).^(plist(p,1:k)') ) * identicalPerms;
    end
    
    totkPaths(k) = totkPaths(k) - walks2subtract(k);
    totPaths = totPaths + totkPaths(k);
    totProb = totProb + totkPaths(k)*(1/3)^k;
end

probMoreThanSoccerExpected = round(1-totProb, 7);  % final answer = 0.4480326