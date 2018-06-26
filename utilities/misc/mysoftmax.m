function A = mysoftmax(N)

A = exp(N);
for ind1 = 1:size(A,1)
    A(ind1,:) = A(ind1,:)./sum(A(ind1,:));
end