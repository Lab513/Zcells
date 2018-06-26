classdef dirtypointer < handle
   properties
      value=[];
   end
 
   methods
      function obj=dirtypointer(value)
         obj.value=value;
      end
   end
end