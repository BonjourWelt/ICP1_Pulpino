//  
//  
//  ------------------------------------------------------------
//    STMicroelectronics N.V. 2010
//   All rights reserved. Reproduction in whole or part is prohibited  without the written consent of the copyright holder.                                                                                                                                                                                                                                                                                                                           
//    STMicroelectronics RESERVES THE RIGHTS TO MAKE CHANGES WITHOUT  NOTICE AT ANY TIME.
//  STMicroelectronics MAKES NO WARRANTY,  EXPRESSED, IMPLIED OR STATUTORY, INCLUDING BUT NOT LIMITED TO ANY IMPLIED  WARRANTY OR MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE,  OR THAT THE USE WILL NOT INFRINGE ANY THIRD PARTY PATENT,  COPYRIGHT OR TRADEMARK.
//  STMicroelectronics SHALL NOT BE LIABLE  FOR ANY LOSS OR DAMAGE ARISING FROM THE USE OF ITS LIBRARIES OR  SOFTWARE.
//    STMicroelectronics
//   850, Rue Jean Monnet
//   BP 16 - 38921 Crolles Cedex - France
//   Central R&D / DAIS.
//                                                                                                                                                                                                                                                                                                                                                                             
//    
//  
//  ------------------------------------------------------------
//  
//  
//    User           : sophie dumont           
//    Project        : CMP_EIT_100909          
//    Division       : Not known               
//    Creation date  : 09 September 2010       
//    Generator mode : MemConfMAT10/distributed
//    
//    WebGen configuration             : C65LP_ST_SPHS:303,29:MemConfMAT10/distributed:3.1-00
//  
//    HDL C65_ST_SPHS Compiler version : 5.3.a@20090417.0 (UPT date)                          
//    
//  
//  For more information about the cuts or the generation environment, please
//  refer to files uk.env and ugnGuiSetupDB in directory DESIGN_DATA.
//   
//  
//  





/****************************************************************
--  Description         : Verilog Model for SPHSLP cmos65
--  Last modified in    : 5.3.a
--  Date                : April, 2009
--  Last modified by    : SK 
--
****************************************************************/
 

/******************** START OF HEADER****************************
   This Header Gives Information about the parameters & options present in the Model

   words = 2048
   bits  = 8
   mux   = 8 
   
   
   
   

**********************END OF HEADER ******************************/
   


`ifdef slm
        `define functional
`endif
`celldefine
`suppress_faults
`enable_portfaults
`ifdef functional
   `timescale 1ns / 1ns
   `delay_mode_unit
`endif

`ifdef functional

module ST_SPHS_2048x8m8_L (Q, RY,CK, CSN, TBYPASS, WEN, A, D    );

    
    
    parameter 
        Corruption_Read_Violation = 1,
        Fault_file_name = "ST_SPHS_2048x8m8_L_faults.txt",   
        ConfigFault = 0,
        max_faults = 20;
   
   // Parameters for Memory Initialization at 0 ns
    parameter 
        MEM_INITIALIZE = 1'b0,
        BinaryInit     = 1'b0,
        InitFileName   = "ST_SPHS_2048x8m8_L.cde",
        InstancePath = "ST_SPHS_2048x8m8_L",
        Debug_mode = "all_warning_mode";
    
    parameter
        Words = 2048,
        Bits = 8,
        Addr = 11,
        mux = 8;




   
    parameter
        Rows = Words/mux,
        WordX = 8'bx,
        AddrX = 11'bx,
        Word0 = 8'b0,
        X = 1'bx;


         
      
        //  INPUT OUTPUT PORTS
        // ========================
      
	output [Bits-1 : 0] Q;
        
        output RY;   
        
        input [Bits-1 : 0] D;
	input [Addr-1 : 0] A;
	        
        input CK, CSN, TBYPASS, WEN;

        
        
        

           
        
        
	reg [Bits-1 : 0] Qint; 

    
        //  WIRE DECLARATION
        //  =====================
        
        
	wire [Bits-1 : 0] Dint,Mint;
        
        assign Mint=8'b0;
        
	wire [Addr-1 : 0] Aint;
	wire CKint;
	wire CSNint;
	wire WENint;

        
        
        wire TBYPASSint;
        
 
        

        
        wire RYint;
        
        
        assign RY =   RYint; 
        reg RY_outreg, RY_out;
        assign RYint = RY_out;
        
        

        
        
        //  REG DECLARATION
        //  ====================
        
	//Output Register for tbypass
        reg [Bits-1 : 0] tbydata;
        //delayed Output Register
        reg [Bits-1 : 0] delOutReg_data;
        reg [Bits-1 : 0] OutReg_data;   // Data Output register
	reg [Bits-1 : 0] tempMem;
	reg lastCK;
        reg CSNreg;	

        `ifdef slm
        `else
	reg [Bits-1 : 0] Mem [Words-1 : 0]; // RAM array
        `endif
	
	reg [Bits-1 :0] Mem_temp;
	reg ValidAddress;
	reg ValidDebugCode;

        
        
        reg WENreg;
        
        
        /* This register is used to force all warning messages 
        ** OFF during run time.
        ** It is a 2 bit register.
        ** USAGE :
        ** debug_level_off = 2'b00 -> ALL WARNING MESSAGES will be DISPLAYED 
        ** debug_level = 2'b10 -> ALL WARNING MESSAGES will NOT be DISPLAYED.
        ** It will override the value of debug_mode, i.e
        ** if debug_mode = "all_warning_mode", then also
        ** no warning messages will be displayed.     
        ** debug_level = 2'b01 OR 2'b11 -> UNUSED , FOR FUTURE SCALABILITY.
        ** ult, debug_mode will prevail.               
        */ 
         reg [1:0] debug_level;
         reg [8*10: 0] operating_mode;
         reg [8*44: 0] message_status;

        integer d, a, p, i, k, j, l;
        `ifdef slm
           integer MemAddr;
        `endif


        //************************************************************
        //****** CONFIG FAULT IMPLEMENTATION VARIABLES*************** 
        //************************************************************ 

        integer file_ptr, ret_val;
        integer fault_word;
        integer fault_bit;
        integer fcnt, Fault_in_memory;
        integer n, cnt, t;  
        integer FailureLocn [max_faults -1 :0];

        reg [100 : 0] stuck_at;
        reg [200 : 0] tempStr;
        reg [7:0] fault_char;
        reg [7:0] fault_char1; // 8 Bit File Pointer
        reg [Addr -1 : 0] std_fault_word;
        reg [max_faults -1 :0] fault_repair_flag;
        reg [max_faults -1 :0] repair_flag;
        reg [Bits - 1: 0] stuck_at_0fault [max_faults -1 : 0];
        reg [Bits - 1: 0] stuck_at_1fault [max_faults -1 : 0];
        reg [100 : 0] array_stuck_at[max_faults -1 : 0] ; 
        reg msgcnt;
        

        reg [Bits -1 : 0] stuck0;
        reg [Bits -1 : 0] stuck1;

        `ifdef slm
        reg [Bits -1 : 0] slm_temp_data;
        `endif
        

        integer flag_error;
        
        //BUFFER INSTANTIATION
        //=========================
        
        
        assign Q =  Qint; 
        buf bufdata [Bits-1:0] (Dint,D);
        buf bufaddr [Addr-1:0] (Aint,A);
        
	buf (TBYPASSint, TBYPASS);
	buf (CKint, CK);
        
        or (CSNint, CSN,TBYPASSint ); 
	buf (WENint, WEN);
        
        
        
        

           

        

// BEHAVIOURAL MODULE DESCRIPTION
// ================================



task task_insert_faults_in_memory;
begin
   if (ConfigFault)
   begin   
     Fault_in_memory = 1;
     for(i = 0;i< fcnt;i = i+ 1) begin
       if (fault_repair_flag[i] !== 1) begin
         Fault_in_memory = 0;
         if (array_stuck_at[i] === "sa0") begin
         `ifdef slm
            //Read first
            $slm_ReadMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
            //operation
            slm_temp_data = slm_temp_data & stuck_at_0fault[i];
            //write back
            $slm_WriteMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
         `else
            Mem[FailureLocn[i]] = Mem[FailureLocn[i]] & stuck_at_0fault[i];
         `endif
         end //if(array_stuck_at)
                                        
         if(array_stuck_at[i] === "sa1") begin
         `ifdef slm
            //Read first
            $slm_ReadMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
            //operation
            slm_temp_data = slm_temp_data | stuck_at_1fault[i];
            //write back
            $slm_WriteMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
         `else
            Mem[FailureLocn[i]] = Mem[FailureLocn[i]] | stuck_at_1fault[i]; 
         `endif
         end //if(array_stuck_at)
       end   // if(fault_repair_flag
     end    // end of for
   end  
end
endtask


      
task WriteMemX;
begin
   `ifdef slm
   $slm_ResetMemory(MemAddr, WordX);
   `else
    for (i = 0; i < Words; i = i + 1)
       Mem[i] = WordX;
   `endif        
   task_insert_faults_in_memory;
end
endtask

task WriteOutX;                
begin
   OutReg_data = WordX;
end
endtask


task WriteCycle;                  
input [Addr-1 : 0] Address;
reg [Bits-1:0] tempReg1,tempReg2;
integer po,i;
begin
   
   tempReg1 = WordX;
   if (^Address !== X)
   begin
      if (ValidAddress)
      begin
         
         
            `ifdef slm
               $slm_ReadMemoryS(MemAddr, Address, tempReg1);
            `else
               tempReg1 = Mem[Address];
            `endif
                   
            for (po=0;po<Bits;po=po+1)
            begin
               if (Mint[po] === 1'b0)
                  tempReg1[po] = Dint[po];
               else if (Mint[po] === 1'bX)
                  tempReg1[po] = 1'bx;
            end                
         
            `ifdef slm
                $slm_WriteMemory(MemAddr, Address, tempReg1);
            `else
                Mem[Address] = tempReg1;
            `endif
            
      end//if (ValidAddress)
      else
         if(debug_level < 2) $display("%m - %t (MSG_ID 701) WARNING: Address Out Of Range. ",$realtime); 
      task_insert_faults_in_memory;
   end //if (^Address !== X)
   else
   begin
      if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Illegal Value on Address Bus. Memory Corrupted ",$realtime);
      WriteMemX;
      
   end
  
end
endtask

task ReadCycle;
input [Addr-1 : 0] Address;
reg [Bits-1:0] MemData;
integer a;
begin
   if (ValidAddress)
   begin        
      `ifdef slm
         $slm_ReadMemory(MemAddr, Address, MemData);
      `else
         MemData = Mem[Address];
      `endif
   end //if (ValidAddress)  
                
   if(ValidAddress === X)
   begin
      if (Corruption_Read_Violation === 1)
      begin   
         if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Illegal Value on Address Bus. Memory and Output Corrupted ",$realtime);
         WriteMemX;
      end
      else
         if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Illegal Value on Address Bus. Output Corrupted ",$realtime);
      MemData = WordX;
      
   end                        
   else if (ValidAddress === 0)
   begin                        
      if(debug_level < 2) $display("%m - %t (MSG_ID 701) WARNING: Address Out Of Range. Output Corrupted ",$realtime); 
      MemData = WordX;
   end
   
   OutReg_data = MemData;
end
endtask



initial
begin
   // Define format for timing value
  $timeformat (-9, 2, " ns", 0);
  `ifdef slm
  $slm_RegisterMemory(MemAddr, Words, Bits);
  `endif   
  
   debug_level= 2'b0;
   message_status = "All Messages are Switched ON";
  
   
  `ifdef  NO_WARNING_MODE
     debug_level = 2'b10;
     message_status = "All Warning Messages are Switched OFF";
  `endif  
  `ifdef slm
     operating_mode = "SLM";
  `else
     operating_mode = "FUNCTIONAL";
  `endif
if(debug_level !== 2'b10) begin
  $display ("%mINFORMATION ");
  $display ("***************************************");
  $display ("The Model is Operating in %s MODE", operating_mode);
  $display ("%s", message_status);
  if(ConfigFault)
  $display ("Configurable Fault Functionality is ON");   
  else
  $display ("Configurable Fault Functionality is OFF");   
  
  $display ("***************************************");
end     
  if (MEM_INITIALIZE === 1'b1)
  begin   
     `ifdef slm
        if (BinaryInit)
           $slm_LoadMemory(MemAddr, InitFileName, "VERILOG_BIN");
        else
           $slm_LoadMemory(MemAddr, InitFileName, "VERILOG_HEX");

     `else
        if (BinaryInit)
           $readmemb(InitFileName, Mem, 0, Words-1);
        else
           $readmemh(InitFileName, Mem, 0, Words-1);
     `endif
  end   
   
  

  
  RY_out = 1'b1;


        
/*  -----------Implemetation for config fault starts------*/
   msgcnt = X;
   t = 0;
   fault_repair_flag = {max_faults{1'b1}};
   repair_flag = {max_faults{1'b1}};
   if(ConfigFault) 
   begin
      file_ptr = $fopen(Fault_file_name , "r");
      if(file_ptr == 0)
      begin     
          if(debug_level < 3) $display("%m - %t (MSG_ID 201) FAILURE: File cannot be opened ",$realtime);      
      end        
      else                
      begin : read_fault_file
        t = 0;
        for (i = 0; i< max_faults; i= i + 1)
        begin
         
           stuck0 = {Bits{1'b1}};
           stuck1 = {Bits{1'b0}};
           fault_char1 = $fgetc (file_ptr);
           if (fault_char1 == 8'b11111111)
              disable read_fault_file;
           ret_val = $ungetc (fault_char1, file_ptr);
           ret_val = $fgets(tempStr, file_ptr);
           ret_val = $sscanf(tempStr, "%d %d %s",fault_word, fault_bit, stuck_at) ;
           flag_error = 0; 
           if(ret_val !== 0)
           begin         
              if(ret_val == 2 || ret_val == 3)
              begin
                if(ret_val == 2)
                   stuck_at = "sa0";

                if(stuck_at !== "sa0" && stuck_at !== "sa1" && stuck_at !== "none")
                begin
                   if(debug_level < 2) $display("%m - %t (MSG_ID 203) WARNING: Wrong value for stuck at in fault file ",$realtime);
                   flag_error = 1;
                end    
                      
                if(fault_word > Words-1)
                begin
                   if(debug_level < 2) $display("%m - %t (MSG_ID 206) WARNING: Address out of range in fault file ",$realtime);
                   flag_error = 1;
                end    

                if(fault_bit > Bits-1)
                begin  
                   if(debug_level < 2) $display("%m - %t (MSG_ID 205) WARNING: Faulty bit out of range in fault file ",$realtime);
                   flag_error = 1;
                end    

                if(flag_error == 0)
                //Correct Inputs
                begin
                   if(stuck_at === "none")
                   begin
                      if(debug_level < 2) $display("%m - %t (MSG_ID 202) WARNING: No fault injected, empty fault file ",$realtime);
                   end
                   else
                   //Adding the faults
                   begin
                      FailureLocn[t] = fault_word;
                      std_fault_word = fault_word;
                      
                      fault_repair_flag[t] = 1'b0;
                      if (stuck_at === "sa0" )
                      begin
                         stuck0[fault_bit] = 1'b0;         
                         stuck_at_0fault[t] = stuck0;
                      end     
                      if (stuck_at === "sa1" )
                      begin
                         stuck1[fault_bit] = 1'b1;
                         stuck_at_1fault[t] = stuck1; 
                      end

                      array_stuck_at[t] = stuck_at;
                      t = t + 1;
                   end //if(stuck_at === "none")  
                end //if(flag_error == 0)
              end //if(ret_val == 2 || ret_val == 3 
              else
              //wrong number of arguments
              begin
                if(debug_level < 2)
                   $display("%m - %t WARNING :  WRONG VALUES ENTERED FOR FAULTY WORD OR FAULTY BIT OR STUCK_AT IN Fault_file_name", $realtime);
                flag_error = 1;
              end
           end //if(ret_val !== 0)
           else
           begin
              if(debug_level < 2) $display("%m - %t (MSG_ID 202) WARNING: No fault injected, empty fault file ",$realtime);
           end    
        end //for (i = 0; i< m
      end //begin: read_fault_file  
      $fclose (file_ptr);

      fcnt = t;

      
      //fault injection at time 0.
      task_insert_faults_in_memory;
   end // config_fault 
end// initial



//+++++++++++++++++++++++++++++++ CONFIG FAULT IMPLEMETATION ENDS+++++++++++++++++++++++++++++++//
        
always @(CKint)
begin
  
      // Unknown Clock Behaviour
      if (CKint=== X && CSNint !==1)
      begin
         WriteOutX;
         WriteMemX;
          
         RY_out = 1'bX;
      end
      if(CKint === 1'b1 && lastCK === 1'b0)
      begin
         CSNreg = CSNint;
         WENreg = WENint;
         if (CSNint !== 1)
         begin
            if (^Aint === X)
               ValidAddress = X;
            else if (Aint < Words)
               ValidAddress = 1;
            else    
               ValidAddress = 0;

            if (ValidAddress)
	       `ifdef slm
               $slm_ReadMemoryS(MemAddr, Aint, Mem_temp);
               `else        
               Mem_temp = Mem[Aint];
               `endif       
            else
	       Mem_temp = WordX; 
               
            
         end// CSNint !==1...
      end // if(CKint === 1'b1...)
        
   /*---------------------- Normal Read and Write -----------------*/

      if (CSNint !== 1 && CKint === 1'b1 && lastCK === 1'b0 )
      begin
            if (CSNint === 0)
            begin        
               
               if (ValidAddress !== 1'bX )   
                  RY_outreg = ~CKint;
               else
                  RY_outreg = 1'bX;
               if (WENint === 1)
               begin
                  ReadCycle(Aint);
               end
               else if (WENint === 0)
               begin
                  
                   WriteCycle(Aint);
                   
               end
               else if (WENint === X)
               begin
                  // Uncertain write cycle
                  WriteOutX;
                  WriteMemX;
                  
                  RY_outreg = 1'bX;
                  if(debug_level < 2) $display("%m - %t (MSG_ID 002) WARNING: Illegal Value on Write Enable. Memory and Output Corrupted ",$realtime);
                  
               end // if (WENint === X...)
            end //if (CSNint === 0
            else if (CSNint === X)
            begin
                
                RY_outreg = 1'bX;
                if(debug_level < 2) $display("%m - %t (MSG_ID 001) WARNING: Illegal Value on Chip Select. Memory and Output Corrupted ",$realtime);
                WriteOutX;
                WriteMemX;
            end //else if (CSNint === X)
         
       
       
      end // if (CSNint !==1..          

   
   lastCK = CKint;
end // always @(CKint)
        
always @(CSNint)
begin
     // Unknown Clock & CSN signal
     if (CSNint !== 1 && CKint === 1'bx)
     begin
       if(debug_level < 2) $display("%m - %t (MSG_ID 004) WARNING: Chip Select going low while Clock is Invalid. Memory Corrupted ",$realtime);
       WriteMemX;
       WriteOutX;
       
       RY_out = 1'bX;
     end
end



//TBYPASS functionality
 always @(TBYPASSint)
 begin
     
             
      
        OutReg_data = WordX;
        if(TBYPASSint === 1'b1) 
          tbydata = Dint;
        else
          tbydata = WordX;
          
    
    
    
 end //end of always TBYPASSint

 always @(Dint)
 begin
    
     
       
      if(TBYPASSint === 1'b1)
        tbydata = Dint;
      
    
    
    
 end //end of always Dint

//assign output data
always @(OutReg_data)
   #1 delOutReg_data = OutReg_data;

always @(delOutReg_data or tbydata or TBYPASSint)
   if(TBYPASSint === 1'b0)
      Qint = delOutReg_data;
   else if(TBYPASSint === 1'bX)
      Qint = WordX;
   else
      Qint = tbydata;      

 
 always @(TBYPASSint)
 begin
    
     
      
      if(TBYPASSint !== 1'b0)
        RY_outreg = 1'bx;
        
    
    
    
 end

 always @(negedge CKint)
 begin
    
     
      
      if(TBYPASSint === 1'b1)
        RY_outreg = 1'b1;
      else if (TBYPASSint === 1'b0) 
         if(CSNreg === 1'b0 && WENreg !== 1'bX && ValidAddress !== 1'bX  && RY_outreg !== 1'bX)
            RY_outreg = ~CKint;
            
    
    
    
 end

always @(RY_outreg)
begin
  #1 RY_out = RY_outreg;
end





endmodule


`else

`timescale 1ns / 1ps
`delay_mode_path
 
module ST_SPHS_2048x8m8_L_main (Q_glitch,  Q_data, Q_gCK , RY_rfCK, RY_rrCK, RY_frCK, ICRY, delTBYPASS, TBYPASS_D_Q, TBYPASS_main, CK,  CSN, TBYPASS, WEN,  A, D, M,debug_level , TimingViol_addr, TimingViol_data, TimingViol_csn, TimingViol_wen, TimingViol_tckh, TimingViol_tckl, TimingViol_tcycle, TimingViol_tbypass, TimingViol_mask     );

    
       
    parameter 
        Corruption_Read_Violation = 1,
        Fault_file_name = "ST_SPHS_2048x8m8_L_faults.txt",   
        ConfigFault = 0,
        max_faults = 20;
   
    // Parameters for Memory Initialization at 0 ns
    parameter 
        MEM_INITIALIZE = 1'b0,
        BinaryInit     = 1'b0,
        InitFileName   = "ST_SPHS_2048x8m8_L.cde",
        InstancePath = "ST_SPHS_2048x8m8_L",
        Debug_mode = "all_warning_mode";
    
    parameter
        Words = 2048,
        Bits = 8,
        Addr = 11,
        mux = 8,
        Rows = Words/mux;




   
    parameter
        WordX = 8'bx,
        AddrX = 11'bx,
        Word0 = 8'b0,
        X = 1'bx;
         
      
        //  INPUT OUTPUT PORTS
        // ========================
	output [Bits-1 : 0] Q_glitch;
	output [Bits-1 : 0] Q_data;
	output [Bits-1 : 0] Q_gCK;
        
        output ICRY;
        output RY_rfCK;
	output RY_rrCK;
	output RY_frCK;   
	output [Bits-1 : 0] delTBYPASS; 
	output TBYPASS_main; 
        output [Bits-1 : 0] TBYPASS_D_Q;
        
        input [Bits-1 : 0] D,M;
	input [Addr-1 : 0] A;
	input CK, CSN, TBYPASS, WEN;
        input [1 : 0] debug_level;

	input [Bits-1 : 0] TimingViol_data, TimingViol_mask;
	input TimingViol_addr, TimingViol_csn, TimingViol_wen, TimingViol_tckh, TimingViol_tckl, TimingViol_tcycle, TimingViol_tbypass;

        
        
 



        
        wire [Bits-1 : 0] Dint,Mint; 
	wire [Addr-1 : 0] Aint;
	wire CKint;
	wire CSNint;
	wire WENint;
        
        


        
        
        
	wire  Mreg_0;
	wire  Mreg_1;
	wire  Mreg_2;
	wire  Mreg_3;
	wire  Mreg_4;
	wire  Mreg_5;
	wire  Mreg_6;
	wire  Mreg_7;
	
	reg [Bits-1 : 0] OutReg_glitch; // Glitch Output register
	reg [Bits-1 : 0] OutReg_data;   // Data Output register
	reg [Bits-1 : 0] Dreg,Mreg;
	reg [Bits-1 : 0] Mreg_temp;
	reg [Bits-1 : 0] tempMem;
	reg [Bits-1 : 0] prevMem;
	reg [Addr-1 : 0] Areg;
	reg [Bits-1 : 0] Q_gCKreg; 
	reg [Bits-1 : 0] lastQ_gCK;
	reg [Bits-1 : 0] last_Qdata;
	reg lastCK, CKreg;
	reg CSNreg;
	reg WENreg;
	
        reg [Bits-1 : 0] TimingViol_data_last;
        reg [Bits-1 : 0] TimingViol_mask_last;
	
	reg [Bits-1 : 0] Mem [Words-1 : 0]; // RAM array
	
	reg [Bits-1 :0] Mem_temp;
	reg ValidAddress;
	reg ValidDebugCode;
	reg ICGFlag;
        



        
       
        
        
        

        integer d, a, p, i, k, j, l;

        //************************************************************
        //****** CONFIG FAULT IMPLEMENTATION VARIABLES*************** 
        //************************************************************ 

        integer file_ptr, ret_val;
        integer fault_word;
        integer fault_bit;
        integer fcnt, Fault_in_memory;
        integer n, cnt, t;  
        integer FailureLocn [max_faults -1 :0];

        reg [100 : 0] stuck_at;
        reg [200 : 0] tempStr;
        reg [7:0] fault_char;
        reg [7:0] fault_char1; // 8 Bit File Pointer
        reg [Addr -1 : 0] std_fault_word;
        reg [max_faults -1 :0] fault_repair_flag;
        reg [max_faults -1 :0] repair_flag;
        reg [Bits - 1: 0] stuck_at_0fault [max_faults -1 : 0];
        reg [Bits - 1: 0] stuck_at_1fault [max_faults -1 : 0];
        reg [100 : 0] array_stuck_at[max_faults -1 : 0] ; 
        reg msgcnt;
        

        reg [Bits -1 : 0] stuck0;
        reg [Bits -1 : 0] stuck1;

        integer flag_error;


	assign Mreg_0 = Mreg[0];
	assign Mreg_1 = Mreg[1];
	assign Mreg_2 = Mreg[2];
	assign Mreg_3 = Mreg[3];
	assign Mreg_4 = Mreg[4];
	assign Mreg_5 = Mreg[5];
	assign Mreg_6 = Mreg[6];
	assign Mreg_7 = Mreg[7];

        //BUFFER INSTANTIATION
        //=========================
        
        buf bufdint [Bits-1:0] (Dint, D);

        buf bufmint [Bits-1:0] (Mint, M);
        
        buf bufaint [Addr-1:0] (Aint, A);
	
	buf (TBYPASS_main, TBYPASS);
	buf (CKint, CK);
        
        buf (CSNint, CSN); 
	buf (WENint, WEN);

        //TBYPASS functionality
        buf bufdeltb [Bits-1:0] (delTBYPASS, TBYPASS);
        
           
        buf bugtbdq [Bits-1:0] (TBYPASS_D_Q, D);

        
        


        
        
        

        wire RY_rfCKint, RY_rrCKint, RY_frCKint, ICRYFlagint;
        reg RY_rfCKreg, RY_rrCKreg, RY_frCKreg; 
	reg InitialRYFlag, ICRYFlag;
        
        buf (RY_rfCK, RY_rfCKint);
	buf (RY_rrCK, RY_rrCKint);
	buf (RY_frCK, RY_frCKint); 
        
        buf (ICRY, ICRYFlagint);
        assign ICRYFlagint = ICRYFlag;
        
        
    specify
        specparam

            tdq = 0.01,
            ttmq = 0.01,
            
            taa_ry = 1.0,
            th_ry = 0.9,
            tck_ry = 1.0,
            taa = 1.0,
            th = 0.9;
        /*-------------------- Propagation Delays ------------------*/
	if (WENreg && !ICGFlag) (CK *> (Q_data[0] : D[0])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[1] : D[1])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[2] : D[2])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[3] : D[3])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[4] : D[4])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[5] : D[5])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[6] : D[6])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[7] : D[7])) = (taa, taa);

	if (!ICGFlag) (CK *> (Q_glitch[0] : D[0])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[1] : D[1])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[2] : D[2])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[3] : D[3])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[4] : D[4])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[5] : D[5])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[6] : D[6])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[7] : D[7])) = (th, th);

	if (!ICGFlag) (CK *> (Q_gCK[0] : D[0])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[1] : D[1])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[2] : D[2])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[3] : D[3])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[4] : D[4])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[5] : D[5])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[6] : D[6])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[7] : D[7])) = (th, th);

	if (!TBYPASS) (TBYPASS *> delTBYPASS[0]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[1]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[2]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[3]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[4]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[5]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[6]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[7]) = (0);
	if (TBYPASS) (TBYPASS *> delTBYPASS[0]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[1]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[2]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[3]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[4]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[5]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[6]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[7]) = (ttmq);
      (D[0] *> TBYPASS_D_Q[0]) = (tdq, tdq);
      (D[1] *> TBYPASS_D_Q[1]) = (tdq, tdq);
      (D[2] *> TBYPASS_D_Q[2]) = (tdq, tdq);
      (D[3] *> TBYPASS_D_Q[3]) = (tdq, tdq);
      (D[4] *> TBYPASS_D_Q[4]) = (tdq, tdq);
      (D[5] *> TBYPASS_D_Q[5]) = (tdq, tdq);
      (D[6] *> TBYPASS_D_Q[6]) = (tdq, tdq);
      (D[7] *> TBYPASS_D_Q[7]) = (tdq, tdq);


        // RY functionality
	if (!ICRY && InitialRYFlag) (CK *> RY_rfCK) = (th_ry, th_ry);
	if (!ICRY && InitialRYFlag) (CK *> RY_rrCK) = (taa_ry, taa_ry);
	if (!ICRY && InitialRYFlag) (CK *> RY_frCK) = (tck_ry, tck_ry);   

	endspecify


assign #0 Q_data = OutReg_data;
assign Q_glitch = OutReg_glitch; 
assign Q_gCK = Q_gCKreg;

    // BEHAVIOURAL MODULE DESCRIPTION



task task_insert_faults_in_memory;
begin
   if (ConfigFault)
   begin   
     Fault_in_memory = 1;
     for(i = 0;i< fcnt;i = i+ 1) begin
       if (fault_repair_flag[i] !== 1) begin
         Fault_in_memory = 0;
         if (array_stuck_at[i] === "sa0") begin
         `ifdef slm
            //Read first
            $slm_ReadMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
            //operation
            slm_temp_data = slm_temp_data & stuck_at_0fault[i];
            //write back
            $slm_WriteMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
         `else
            Mem[FailureLocn[i]] = Mem[FailureLocn[i]] & stuck_at_0fault[i];
         `endif
         end //if(array_stuck_at)
                                        
         if(array_stuck_at[i] === "sa1") begin
         `ifdef slm
            //Read first
            $slm_ReadMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
            //operation
            slm_temp_data = slm_temp_data | stuck_at_1fault[i];
            //write back
            $slm_WriteMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
         `else
            Mem[FailureLocn[i]] = Mem[FailureLocn[i]] | stuck_at_1fault[i]; 
         `endif
         end //if(array_stuck_at)
       end   // if(fault_repair_flag
     end    // end of for
   end  
end
endtask



task chstate;
   input [Bits-1 : 0] clkin;
   output [Bits-1 : 0] clkout;
   integer d;
begin
   if ( $realtime != 0 )
      for (d = 0; d < Bits; d = d + 1)
      begin
         if (clkin[d] === 1'b0)
            clkout[d] = 1'b1;
         else if (clkin[d] === 1'b1)
            clkout[d] = 1'bx;
         else
            clkout[d] = 1'b0;
      end
end
endtask


task WriteMemX;
begin
   for (i = 0; i < Words; i = i + 1)
       Mem[i] = WordX;
   task_insert_faults_in_memory;
end
endtask

task WriteLocMskX_bwise;
   input [Addr-1 : 0] Address;
   input [Bits-1 : 0] Mask;
begin
   if (^Address !== X)
   begin
      tempMem = Mem[Address];
             
      for (j = 0;j< Bits; j=j+1)
         if (Mask[j] === 1'bx)
            tempMem[j] = 1'bx;
                    
      Mem[Address] = tempMem;
      task_insert_faults_in_memory;
   end//if (^Address !== X
   else
      WriteMemX;
end
endtask
    
task WriteOutX;                
begin
   OutReg_data= WordX;
   OutReg_glitch= WordX;
end
endtask

task WriteCycle;                  
   input [Addr-1 : 0] Address;
   reg [Bits-1:0] tempReg1,tempReg2;
   integer po,i;
begin
  
   tempReg1 = WordX;
   if (^Address !== X)
   begin
      if (ValidAddress)
      begin
         
             tempReg1 = Mem[Address];
             for (po=0;po<Bits;po=po+1)
                if (Mreg[po] === 1'b0)
                   tempReg1[po] = Dreg[po];
                else if (Mreg[po] === 1'bX)
                    tempReg1[po] = 1'bx;
                        
                Mem[Address] = tempReg1;
                     
      end //if (ValidAddress)
      else
         if(debug_level < 2) $display("%m - %t (MSG_ID 701) WARNING: Write Port:  Address Out Of Range. ",$realtime);
      task_insert_faults_in_memory;
   end//if (^Address !== X)
   else
   begin
      if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Write Port:  Illegal Value on Address Bus. Memory Corrupted ",$realtime);
      WriteMemX;
      
   end
   
end
endtask

task ReadCycle;
   input [Addr-1 : 0] Address;
   reg [Bits-1:0] MemData;
   integer a;
begin

   if (ValidAddress)
      MemData = Mem[Address];

   if(ValidAddress === X)
   begin
      if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Read Port:  Illegal Value on Address Bus. Memory and Output Corrupted ",$realtime);
      MemData = WordX;
      WriteMemX;
      
   end                        
   else if (ValidAddress === 0)
   begin                        
      if(debug_level < 2) $display("%m - %t (MSG_ID 701) WARNING: Read Port:  Address Out Of Range. Output Corrupted ",$realtime);
      MemData = WordX;
   end

   for (a = 0; a < Bits; a = a + 1)
   begin
      if (MemData[a] !== OutReg_data[a])
         OutReg_glitch[a] = WordX[a];
      else
         OutReg_glitch[a] = MemData[a];
   end//for (a = 0; a <

   OutReg_data = MemData;
   last_Qdata = Q_data;

end
endtask




assign RY_rfCKint = RY_rfCKreg;
assign RY_frCKint = RY_frCKreg;
assign RY_rrCKint = RY_rrCKreg;

// Define format for timing value
initial
begin
   $timeformat (-9, 2, " ns", 0);
   ICGFlag = 0;

   //Initialize Memory
   if (MEM_INITIALIZE === 1'b1)
   begin   
      if (BinaryInit)
         $readmemb(InitFileName, Mem, 0, Words-1);
      else
         $readmemh(InitFileName, Mem, 0, Words-1);
   end

   
   ICRYFlag = 1;
   InitialRYFlag = 0;
   ICRYFlag <= 0;
   RY_rfCKreg = 1'b1;
   RY_rrCKreg = 1'b1;
   RY_frCKreg = 1'b1;

   
   

/*  -----------Implementation for config fault starts------*/
   msgcnt = X;
   t = 0;
   fault_repair_flag = {max_faults{1'b1}};
   repair_flag = {max_faults{1'b1}};
   if(ConfigFault) 
   begin
      file_ptr = $fopen(Fault_file_name , "r");
      if(file_ptr == 0)
      begin     
          if(debug_level < 3) $display("%m - %t (MSG_ID 201) FAILURE: File cannot be opened ",$realtime);      
      end        
      else                
      begin : read_fault_file
        t = 0;
        for (i = 0; i< max_faults; i= i + 1)
        begin
         
           stuck0 = {Bits{1'b1}};
           stuck1 = {Bits{1'b0}};
           fault_char1 = $fgetc (file_ptr);
           if (fault_char1 == 8'b11111111)
              disable read_fault_file;
           ret_val = $ungetc (fault_char1, file_ptr);
           ret_val = $fgets(tempStr, file_ptr);
           ret_val = $sscanf(tempStr, "%d %d %s",fault_word, fault_bit, stuck_at) ;
           flag_error = 0; 
           if(ret_val !== 0)
           begin         
              if(ret_val == 2 || ret_val == 3)
              begin
                if(ret_val == 2)
                   stuck_at = "sa0";

                if(stuck_at !== "sa0" && stuck_at !== "sa1" && stuck_at !== "none")
                begin
                   if(debug_level < 2) $display("%m - %t (MSG_ID 203) WARNING: Wrong value for stuck at in fault file ",$realtime);
                   flag_error = 1;
                end    
                      
                if(fault_word > Words-1)
                begin
                   if(debug_level < 2) $display("%m - %t (MSG_ID 206) WARNING: Address out of range in fault file ",$realtime);
                   flag_error = 1;
                end    

                if(fault_bit > Bits-1)
                begin  
                   if(debug_level < 2) $display("%m - %t (MSG_ID 205) WARNING: Faulty bit out of range in fault file ",$realtime);
                   flag_error = 1;
                end    

                if(flag_error == 0)
                //Correct Inputs
                begin
                   if(stuck_at === "none")
                   begin
                      if(debug_level < 2) $display("%m - %t (MSG_ID 202) WARNING: No fault injected, empty fault file ",$realtime);
                   end
                   else
                   //Adding the faults
                   begin
                      FailureLocn[t] = fault_word;
                      std_fault_word = fault_word;
                      
                      fault_repair_flag[t] = 1'b0;
                      if (stuck_at === "sa0" )
                      begin
                         stuck0[fault_bit] = 1'b0;         
                         stuck_at_0fault[t] = stuck0;
                      end     
                      if (stuck_at === "sa1" )
                      begin
                         stuck1[fault_bit] = 1'b1;
                         stuck_at_1fault[t] = stuck1; 
                      end

                      array_stuck_at[t] = stuck_at;
                      t = t + 1;
                   end //if(stuck_at === "none")  
                end //if(flag_error == 0)
              end //if(ret_val == 2 || ret_val == 3 
              else
              //wrong number of arguments
              begin
                if(debug_level < 2)
                   $display("%m - %t WARNING :  WRONG VALUES ENTERED FOR FAULTY WORD OR FAULTY BIT OR STUCK_AT IN Fault_file_name", $realtime);
                flag_error = 1;
              end
           end //if(ret_val !== 0)
           else
           begin
              if(debug_level < 2) $display("%m - %t (MSG_ID 202) WARNING: No fault injected, empty fault file ",$realtime);
           end    
        end //for (i = 0; i< m
      end //begin: read_fault_file  
      $fclose (file_ptr);

      fcnt = t;
      
      task_insert_faults_in_memory;
   end // config_fault 
end// initial



//+++++++++++++++++++++++++++++++ CONFIG FAULT IMPLEMETATION ENDS+++++++++++++++++++++++++++++++//

always @(CKint)
begin
   lastCK = CKreg;
   CKreg = CKint;
   
   if (CKint !== 0 && CSNint !== 1)
   begin
     InitialRYFlag = 1;
   end
   
      // Unknown Clock Behaviour
      if (((CKint=== X && CSNint !==1) || (CKint=== X && CSNreg !==1 && lastCK ===1)))
      begin
         
         ICRYFlag = 1;   
         chstate(Q_gCKreg, Q_gCKreg);
	 WriteOutX;
         WriteMemX;
      end//if (((CKint===
                
   
   if (CKint===1 && lastCK ===0 && CSNint === X  )
       ICRYFlag = 1;
   else if (CKint === 1 && lastCK === 0 && CSNint === 0 )
       ICRYFlag = 0;
   

   /*---------------------- Latching signals ----------------------*/
   if(CKreg === 1'b1 && lastCK === 1'b0)
   begin
      if (CSNint !== 1)
      begin
         ICGFlag = 0;
         Dreg = Dint;
         Mreg = Mint;
         WENreg = WENint;
         Areg = Aint;
         if (^Areg === X)
            ValidAddress = X;
         else if (Areg < Words)
            ValidAddress = 1;
         else
            ValidAddress = 0;

         if (ValidAddress)
            Mem_temp = Mem[Aint];
         else
            Mem_temp = WordX; 

         
      end//if (CSNint !== 1)
         
      CSNreg = CSNint;
      last_Qdata = Q_data;
      
      
   end//if(CKreg === 1'b1 && lastCK =   
     
   /*---------------------- Normal Read and Write -----------------*/

   if ((CSNreg !== 1) && (CKreg === 1 && lastCK === 0))
   begin
      if (WENreg === 1'b1 && CSNreg === 1'b0)
      begin
         ReadCycle(Areg);
         chstate(Q_gCKreg, Q_gCKreg);
      end//if (WENreg === 1 && C
      else if (WENreg === 0 && CSNreg === 0)
      begin
          
           WriteCycle(Areg);
           
      end
      /*---------- Corruption due to faulty values on signals --------*/
      else if (CSNreg === 1'bX)
      begin
         // Uncertain cycle
         if(debug_level < 2) $display("%m - %t (MSG_ID 001) WARNING: Illegal Value on Chip Select. Memory and Output Corrupted ",$realtime);
         WriteMemX;
         WriteOutX;
         chstate(Q_gCKreg, Q_gCKreg);
      end//else if (CSN === 1'bX
      else if (WENreg === X)
      begin
         // Uncertain write cycle
         if(debug_level < 2) $display("%m - %t (MSG_ID 002) WARNING: Illegal Value on Write Enable. Memory and Output Corrupted ",$realtime);
         WriteMemX;
         WriteOutX;
         chstate(Q_gCKreg, Q_gCKreg);
         
         ICRYFlag = 1;
         
      end//else if (WENreg ===
      
      

   end //if ((CSNreg !== 1) && (CKreg    
   
end // always @(CKint)

always @(CSNint)
begin   
     // Unknown Clock & CSN signal
     if (CSNint !== 1 && CKint === X )
     begin
       if(debug_level < 2) $display("%m - %t (MSG_ID 003) WARNING: Illegal Value on Clock. Memory and Output Corrupted ",$realtime);
       chstate(Q_gCKreg, Q_gCKreg);
       WriteMemX;
       WriteOutX;
       
       ICRYFlag = 1;
     end//if (CSNint !== 1
end      


 always @(TBYPASS_main)
 begin
 
      if (TBYPASS_main !== 0)
        
        ICRYFlag = 1;
      OutReg_data = WordX;
      OutReg_glitch = WordX;
    
 end


  

        /*---------------RY Functionality-----------------*/
always @(posedge CKreg)
begin

     
     if ((CSNreg === 0) && (CKreg === 1 && lastCK === 0) && TBYPASS_main === 1'b0)
     begin
       if (WENreg !== 1'bX && ValidAddress !== 1'bX)
       begin
         RY_rfCKreg = ~RY_rfCKreg;
         RY_rrCKreg = ~RY_rrCKreg;
       end
       else
         ICRYFlag = 1'b1; 
     end
     
     
end

 always @(negedge CKreg)
 begin
 
      
      if (TBYPASS_main === 1'b1)
      begin
        RY_frCKreg = ~RY_frCKreg;
        ICRYFlag = 1'b0;
      end  
      else if (TBYPASS_main === 1'b0 && (CSNreg === 0) && (CKreg === 0 && lastCK === 1))
      begin
        if (WENreg !== 1'bX && ValidAddress !== 1'bX)
           RY_frCKreg = ~RY_frCKreg;
      end
      
     
     
   
 end

always @ (TimingViol_tckl or TimingViol_tcycle or TimingViol_csn or TimingViol_tckh or TimingViol_tbypass or TimingViol_wen or TimingViol_addr  )
ICRYFlag = 1;
        /*---------------------------------*/





/*---------------TBYPASS  Functionality in functional model -----------------*/

always @(TimingViol_data)
// tds or tdh violation
begin
#0
   for (l = 0; l < Bits; l = l + 1)
   begin   
      if((TimingViol_data[l] !== TimingViol_data_last[l]))
         Mreg[l] = 1'bx;
   end   
   WriteLocMskX_bwise(Areg,Mreg);
   TimingViol_data_last = TimingViol_data;
end


        
/*---------- Corruption due to Timing Violations ---------------*/

always @(TimingViol_tckl or TimingViol_tcycle)
// tckl -  tcycle
begin
#0
   WriteOutX;
   #0.00 WriteMemX;
end

always @(TimingViol_csn)
// tps or tph
begin
#0
   CSNreg = 1'bX;
   WriteOutX;
   WriteMemX;  
   if (CSNreg === 1)
   begin
      chstate(Q_gCKreg, Q_gCKreg);
   end
end

always @(TimingViol_tckh)
// tckh
begin
#0
   ICGFlag = 1;
   chstate(Q_gCKreg, Q_gCKreg);
   WriteOutX;
   WriteMemX;
end

always @(TimingViol_addr)
// tas or tah
begin
#0
   if (WENreg !== 0)
      WriteOutX;
   WriteMemX;
   
end


always @(TimingViol_wen)
//tws or twh
begin
#0
   WriteMemX; 
   WriteOutX;
end


always @(TimingViol_tbypass)
//ttmck
begin
#0
   WriteOutX;
   WriteMemX;  
end







endmodule

module ST_SPHS_2048x8m8_L_OPschlr (QINT,  RYINT, Q_gCK, Q_glitch,  Q_data, RY_rfCK, RY_rrCK, RY_frCK, ICRY, delTBYPASS, TBYPASS_D_Q, TBYPASS_main);

    parameter
        Words = 2048,
        Bits = 8,
        Addr = 11;
        

    parameter
        WordX = 8'bx,
        AddrX = 11'bx,
        X = 1'bx;

	output [Bits-1 : 0] QINT;
	input [Bits-1 : 0] Q_glitch;
	input [Bits-1 : 0] Q_data;
	input [Bits-1 : 0] Q_gCK;
        input [Bits-1 : 0] TBYPASS_D_Q;
        input [Bits-1 : 0] delTBYPASS;
        input TBYPASS_main;
	
	integer m,a, d, n, o, p;
	wire [Bits-1 : 0] QINTint;
	wire [Bits-1 : 0] QINTERNAL;

        reg [Bits-1 : 0] OutReg;
	reg [Bits-1 : 0] lastQ_gCK, Q_gCKreg;
	reg [Bits-1 : 0] lastQ_data, Q_datareg;
	reg [Bits-1 : 0] QINTERNALreg;
	reg [Bits-1 : 0] lastQINTERNAL;

buf bufqint [Bits-1:0] (QINT, QINTint);

	assign QINTint[0] = (TBYPASS_main===0 && delTBYPASS[0]===0)?OutReg[0] : (TBYPASS_main===1 && delTBYPASS[0]===1)?TBYPASS_D_Q[0] : WordX;
	assign QINTint[1] = (TBYPASS_main===0 && delTBYPASS[1]===0)?OutReg[1] : (TBYPASS_main===1 && delTBYPASS[1]===1)?TBYPASS_D_Q[1] : WordX;
	assign QINTint[2] = (TBYPASS_main===0 && delTBYPASS[2]===0)?OutReg[2] : (TBYPASS_main===1 && delTBYPASS[2]===1)?TBYPASS_D_Q[2] : WordX;
	assign QINTint[3] = (TBYPASS_main===0 && delTBYPASS[3]===0)?OutReg[3] : (TBYPASS_main===1 && delTBYPASS[3]===1)?TBYPASS_D_Q[3] : WordX;
	assign QINTint[4] = (TBYPASS_main===0 && delTBYPASS[4]===0)?OutReg[4] : (TBYPASS_main===1 && delTBYPASS[4]===1)?TBYPASS_D_Q[4] : WordX;
	assign QINTint[5] = (TBYPASS_main===0 && delTBYPASS[5]===0)?OutReg[5] : (TBYPASS_main===1 && delTBYPASS[5]===1)?TBYPASS_D_Q[5] : WordX;
	assign QINTint[6] = (TBYPASS_main===0 && delTBYPASS[6]===0)?OutReg[6] : (TBYPASS_main===1 && delTBYPASS[6]===1)?TBYPASS_D_Q[6] : WordX;
	assign QINTint[7] = (TBYPASS_main===0 && delTBYPASS[7]===0)?OutReg[7] : (TBYPASS_main===1 && delTBYPASS[7]===1)?TBYPASS_D_Q[7] : WordX;
assign QINTERNAL = QINTERNALreg;

always @ (TBYPASS_main)
begin
if (TBYPASS_main === 0 || TBYPASS_main === X) 
     QINTERNALreg = WordX;
end


        
/*------------------ RY functionality -----------------*/
       output RYINT;
        input RY_rfCK, RY_rrCK, RY_frCK, ICRY;
        wire RYINTint;
        reg RYINTreg, RYRiseFlag;

        buf (RYINT, RYINTint);

assign RYINTint = RYINTreg;
        
initial
begin
   RYRiseFlag = 1'b0;
   RYINTreg = 1'b1;
end

always @(ICRY)
begin
   if($realtime == 0)
      RYINTreg = 1'b1;
   else
      RYINTreg = 1'bx;
end

always @(RY_rfCK)
   if (ICRY !== 1)
   begin
      if ($realtime != 0)
      begin   
         RYINTreg = 0;
         RYRiseFlag=0;
      end   
   end


always @(RY_rrCK) 
#0 
   if (ICRY !== 1 && $realtime != 0)
   begin
      if (RYRiseFlag === 0)
      begin
         RYRiseFlag=1;
      end
      else
      begin
         RYINTreg = 1'b1;
         RYRiseFlag=0;
      end
   end


always @(RY_frCK)         
   if (ICRY !== 1 && $realtime != 0)
   begin
      if (RYRiseFlag === 0)
      begin
         RYRiseFlag=1;
      end
      else
      begin
         RYINTreg = 1'b1;
         RYRiseFlag=0;
      end
   end   

/*------------------------------------------------ */

always @(Q_gCK)
begin
#0  //This has been used for removing races during hold time vilations in MODELSIM simulator.
   lastQ_gCK = Q_gCKreg;
   Q_gCKreg <= Q_gCK;
   for (m = 0; m < Bits; m = m + 1)
   begin
      if (lastQ_gCK[m] !== Q_gCK[m])
      begin
        lastQINTERNAL[m] = QINTERNALreg[m];
        QINTERNALreg[m] = Q_glitch[m];
      end
   end
end

always @(Q_data)
begin
#0  //This has been used for removing races during hold time vilations in MODELSIM simulator.
    lastQ_data = Q_datareg;
    Q_datareg <= Q_data;
    for (n = 0; n < Bits; n = n + 1)
    begin
      if (lastQ_data[n] !== Q_data[n])
      begin
       	lastQINTERNAL[n] = QINTERNALreg[n];
        QINTERNALreg[n] = Q_data[n];
      end
    end
end

always @(QINTERNAL)
begin
   for (d = 0; d < Bits; d = d + 1)
   begin
      if (OutReg[d] !== QINTERNAL[d])
         OutReg[d] = QINTERNAL[d];
   end
end



endmodule



module ST_SPHS_2048x8m8_L (Q, RY, CK, CSN, TBYPASS, WEN,  A,  D   );


    parameter 
        Corruption_Read_Violation = 1,
        Fault_file_name = "ST_SPHS_2048x8m8_L_faults.txt",   
        ConfigFault = 0,
        max_faults = 20;
   
    // Parameters for Memory Initialization at 0 ns
    parameter 
        MEM_INITIALIZE = 1'b0,
        BinaryInit     = 1'b0,
        InitFileName   = "ST_SPHS_2048x8m8_L.cde",
        InstancePath = "ST_SPHS_2048x8m8_L",
        Debug_mode = "all_warning_mode";
    
    parameter
        Words = 2048,
        Bits = 8,
        Addr = 11,
        mux = 8;




   
    parameter
        Rows = Words/mux,
        WordX = 8'bx,
        AddrX = 11'bx,
        Word0 = 8'b0,
        X = 1'bx;

        
         
    // INPUT OUTPUT PORTS
    //  ======================

    output [Bits-1 : 0] Q;
    
    output RY;   
    input CK;
    input CSN;
    input WEN;
    input TBYPASS;
    input [Addr-1 : 0] A;
    input [Bits-1 : 0] D;
    
    


   

     

   // WIRE DECLARATIONS
   //======================
   
   wire [Bits-1 : 0] Q_glitchint;
   wire [Bits-1 : 0] Q_dataint;
   wire [Bits-1 : 0] Dint,Mint;
   wire [Addr-1 : 0] Aint;
   wire [Bits-1 : 0] Q_gCKint;
   wire CKint;
   wire CSNint;
   wire WENint;
   wire TBYPASSint;
   wire TBYPASS_mainint;
   wire [Bits-1 : 0]  TBYPASS_D_Qint;
   wire [Bits-1 : 0]  delTBYPASSint;




   wire [Bits-1 : 0] Qint, Q_out;
   
   
   

   //REG DECLARATIONS
   //======================

   reg [Bits-1 : 0] Dreg,Mreg;
   reg [Addr-1 : 0] Areg;
   reg CKreg;
   reg CSNreg;
   reg WENreg;
	
   reg [Bits-1 : 0] TimingViol_data, TimingViol_mask;
   reg [Bits-1 : 0] TimingViol_data_last, TimingViol_mask_last;
	reg TimingViol_data_0, TimingViol_mask_0;
	reg TimingViol_data_1, TimingViol_mask_1;
	reg TimingViol_data_2, TimingViol_mask_2;
	reg TimingViol_data_3, TimingViol_mask_3;
	reg TimingViol_data_4, TimingViol_mask_4;
	reg TimingViol_data_5, TimingViol_mask_5;
	reg TimingViol_data_6, TimingViol_mask_6;
	reg TimingViol_data_7, TimingViol_mask_7;
   reg TimingViol_addr;
   reg TimingViol_csn, TimingViol_wen, TimingViol_tbypass;
   reg TimingViol_tckh, TimingViol_tckl, TimingViol_tcycle;
   




   wire [Bits-1 : 0] MEN,CSWEMTBYPASS;
   wire CSTBYPASSN, CSWETBYPASSN,CS;

   /* This register is used to force all warning messages 
   ** OFF during run time.
   ** 
   */ 
   reg [1:0] debug_level;
   reg [8*10: 0] operating_mode;
   reg [8*44: 0] message_status;


initial
begin
  debug_level = 2'b0;
  message_status = "All Messages are Switched ON";
    
  
  `ifdef  NO_WARNING_MODE
     debug_level = 2'b10;
     message_status = "All Messages are Switched OFF"; 
  `endif 
if(debug_level !== 2'b10) begin
   $display ("%m  INFORMATION");
   $display ("***************************************");
   $display ("The Model is Operating in TIMING MODE");
   $display ("Please make sure that SDF is properly annotated otherwise dummy values will be used");
   $display ("%s", message_status);
   if(ConfigFault)
   $display ("Configurable Fault Functionality is ON");   
   else
   $display ("Configurable Fault Functionality is OFF");
   
   $display ("***************************************");
end     
end     

   
   // BUF DECLARATIONS
   //=====================
   
   buf (CKint, CK);
   or (CSNint, CSN, TBYPASSint);
   buf (TBYPASSint, TBYPASS);
   buf (WENint, WEN);
   buf bufDint [Bits-1:0] (Dint, D);
   
   assign Mint = 8'b0;
   
   buf bufAint [Addr-1:0] (Aint, A);


   assign Q =  Qint;




   


    wire  RYint, RY_rfCKint, RY_rrCKint, RY_frCKint, RY_out;
    reg RY_outreg; 
    assign RY_out = RY_outreg;
    assign RY =   RY_out;
    always @ (RYint)
    begin
       RY_outreg = RYint;
    end

        
    // Only include timing checks during behavioural modelling


    
    assign CS =  CSN;
    or (CSWETBYPASSN, WENint, CSNint);
    or (CSNTBY, CSN, TBYPASSint);  


        
 or (CSWEMTBYPASS[0], Mint[0], CSWETBYPASSN);
 or (CSWEMTBYPASS[1], Mint[1], CSWETBYPASSN);
 or (CSWEMTBYPASS[2], Mint[2], CSWETBYPASSN);
 or (CSWEMTBYPASS[3], Mint[3], CSWETBYPASSN);
 or (CSWEMTBYPASS[4], Mint[4], CSWETBYPASSN);
 or (CSWEMTBYPASS[5], Mint[5], CSWETBYPASSN);
 or (CSWEMTBYPASS[6], Mint[6], CSWETBYPASSN);
 or (CSWEMTBYPASS[7], Mint[7], CSWETBYPASSN);

    specify
    specparam


         tckl_tck_ry = 0.00,
         tcycle_taa_ry = 0.00,

         
         
	 tms = 0.0,
         tmh = 0.0,
         tcycle = 0.0,
         tckh = 0.0,
         tckl = 0.0,
         ttms = 0.0,
         ttmh = 0.0,
         tps = 0.0,
         tph = 0.0,
         tws = 0.0,
         twh = 0.0,
         tas = 0.0,
         tah = 0.0,
         tds = 0.0,
         tdh = 0.0;
        /*---------------------- Timing Checks ---------------------*/

	$setup(posedge A[0], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[1], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[2], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[3], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[4], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[5], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[6], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[7], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[8], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[9], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[10], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[0], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[1], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[2], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[3], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[4], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[5], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[6], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[7], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[8], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[9], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[10], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[0], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[1], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[2], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[3], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[4], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[5], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[6], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[7], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[8], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[9], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[10], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[0], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[1], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[2], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[3], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[4], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[5], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[6], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[7], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[8], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[9], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[10], tah, TimingViol_addr);
	$setup(posedge D[0], posedge CK &&& (CSWEMTBYPASS[0] != 1), tds, TimingViol_data_0);
	$setup(posedge D[1], posedge CK &&& (CSWEMTBYPASS[1] != 1), tds, TimingViol_data_1);
	$setup(posedge D[2], posedge CK &&& (CSWEMTBYPASS[2] != 1), tds, TimingViol_data_2);
	$setup(posedge D[3], posedge CK &&& (CSWEMTBYPASS[3] != 1), tds, TimingViol_data_3);
	$setup(posedge D[4], posedge CK &&& (CSWEMTBYPASS[4] != 1), tds, TimingViol_data_4);
	$setup(posedge D[5], posedge CK &&& (CSWEMTBYPASS[5] != 1), tds, TimingViol_data_5);
	$setup(posedge D[6], posedge CK &&& (CSWEMTBYPASS[6] != 1), tds, TimingViol_data_6);
	$setup(posedge D[7], posedge CK &&& (CSWEMTBYPASS[7] != 1), tds, TimingViol_data_7);
	$setup(negedge D[0], posedge CK &&& (CSWEMTBYPASS[0] != 1), tds, TimingViol_data_0);
	$setup(negedge D[1], posedge CK &&& (CSWEMTBYPASS[1] != 1), tds, TimingViol_data_1);
	$setup(negedge D[2], posedge CK &&& (CSWEMTBYPASS[2] != 1), tds, TimingViol_data_2);
	$setup(negedge D[3], posedge CK &&& (CSWEMTBYPASS[3] != 1), tds, TimingViol_data_3);
	$setup(negedge D[4], posedge CK &&& (CSWEMTBYPASS[4] != 1), tds, TimingViol_data_4);
	$setup(negedge D[5], posedge CK &&& (CSWEMTBYPASS[5] != 1), tds, TimingViol_data_5);
	$setup(negedge D[6], posedge CK &&& (CSWEMTBYPASS[6] != 1), tds, TimingViol_data_6);
	$setup(negedge D[7], posedge CK &&& (CSWEMTBYPASS[7] != 1), tds, TimingViol_data_7);
	$hold(posedge CK &&& (CSWEMTBYPASS[0] != 1), posedge D[0], tdh, TimingViol_data_0);
	$hold(posedge CK &&& (CSWEMTBYPASS[1] != 1), posedge D[1], tdh, TimingViol_data_1);
	$hold(posedge CK &&& (CSWEMTBYPASS[2] != 1), posedge D[2], tdh, TimingViol_data_2);
	$hold(posedge CK &&& (CSWEMTBYPASS[3] != 1), posedge D[3], tdh, TimingViol_data_3);
	$hold(posedge CK &&& (CSWEMTBYPASS[4] != 1), posedge D[4], tdh, TimingViol_data_4);
	$hold(posedge CK &&& (CSWEMTBYPASS[5] != 1), posedge D[5], tdh, TimingViol_data_5);
	$hold(posedge CK &&& (CSWEMTBYPASS[6] != 1), posedge D[6], tdh, TimingViol_data_6);
	$hold(posedge CK &&& (CSWEMTBYPASS[7] != 1), posedge D[7], tdh, TimingViol_data_7);
	$hold(posedge CK &&& (CSWEMTBYPASS[0] != 1), negedge D[0], tdh, TimingViol_data_0);
	$hold(posedge CK &&& (CSWEMTBYPASS[1] != 1), negedge D[1], tdh, TimingViol_data_1);
	$hold(posedge CK &&& (CSWEMTBYPASS[2] != 1), negedge D[2], tdh, TimingViol_data_2);
	$hold(posedge CK &&& (CSWEMTBYPASS[3] != 1), negedge D[3], tdh, TimingViol_data_3);
	$hold(posedge CK &&& (CSWEMTBYPASS[4] != 1), negedge D[4], tdh, TimingViol_data_4);
	$hold(posedge CK &&& (CSWEMTBYPASS[5] != 1), negedge D[5], tdh, TimingViol_data_5);
	$hold(posedge CK &&& (CSWEMTBYPASS[6] != 1), negedge D[6], tdh, TimingViol_data_6);
	$hold(posedge CK &&& (CSWEMTBYPASS[7] != 1), negedge D[7], tdh, TimingViol_data_7);

	
        $setup(posedge CSN, edge[01,0x,x1,1x] CK &&& (TBYPASSint != 1), tps, TimingViol_csn);
	$setup(negedge CSN, edge[01,0x,x1,1x] CK &&& (TBYPASSint != 1), tps, TimingViol_csn);
	$hold(edge[01,0x,x1,x0] CK &&& (TBYPASSint != 1), posedge CSN, tph, TimingViol_csn);
	$hold(edge[01,0x,x1,x0] CK &&& (TBYPASSint != 1), negedge CSN, tph, TimingViol_csn);
        $setup(posedge WEN, edge[01,0x,x1,1x] CK &&& (CSNint != 1), tws, TimingViol_wen);
        $setup(negedge WEN, edge[01,0x,x1,1x] CK &&& (CSNint != 1), tws, TimingViol_wen);
        $hold(edge[01,0x,x1,x0] CK &&& (CSNint != 1), posedge WEN, twh, TimingViol_wen);
        $hold(edge[01,0x,x1,x0] CK &&& (CSNint != 1), negedge WEN, twh, TimingViol_wen);
        $period(posedge CK &&& (CSNint != 1), tcycle, TimingViol_tcycle);
        $width(posedge CK &&& (CSNint != 1'b1), tckh, 0, TimingViol_tckh);
        $width(negedge CK &&& (CSNint != 1'b1), tckl, 0, TimingViol_tckl);
        $setup(posedge TBYPASS, posedge CK &&& (CS != 1),ttms, TimingViol_tbypass);
        $setup(negedge TBYPASS, posedge CK &&& (CS != 1),ttms, TimingViol_tbypass);
        $hold(posedge CK &&& (CS != 1), posedge TBYPASS, ttmh, TimingViol_tbypass); 
        $hold(posedge CK &&& (CS != 1), negedge TBYPASS, ttmh, TimingViol_tbypass); 




	endspecify

always @(CKint)
begin
   CKreg <= CKint;
end

//latch input signals
always @(posedge CKint)
begin
   if (CSNint !== 1)
   begin
      Dreg = Dint;
      Mreg = Mint;
      WENreg = WENint;
      Areg = Aint;
   end
   CSNreg = CSNint;
end
     


// conversion from registers to array elements for data setup violation notifiers

always @(TimingViol_data_0)
begin
   TimingViol_data[0] = TimingViol_data_0;
end


always @(TimingViol_data_1)
begin
   TimingViol_data[1] = TimingViol_data_1;
end


always @(TimingViol_data_2)
begin
   TimingViol_data[2] = TimingViol_data_2;
end


always @(TimingViol_data_3)
begin
   TimingViol_data[3] = TimingViol_data_3;
end


always @(TimingViol_data_4)
begin
   TimingViol_data[4] = TimingViol_data_4;
end


always @(TimingViol_data_5)
begin
   TimingViol_data[5] = TimingViol_data_5;
end


always @(TimingViol_data_6)
begin
   TimingViol_data[6] = TimingViol_data_6;
end


always @(TimingViol_data_7)
begin
   TimingViol_data[7] = TimingViol_data_7;
end




ST_SPHS_2048x8m8_L_main ST_SPHS_2048x8m8_L_maininst (Q_glitchint,  Q_dataint, Q_gCKint , RY_rfCKint, RY_rrCKint, RY_frCKint, ICRYint, delTBYPASSint, TBYPASS_D_Qint, TBYPASS_mainint, CKint,  CSNint , TBYPASSint, WENint,  Aint, Dint, Mint, debug_level  , TimingViol_addr, TimingViol_data, TimingViol_csn, TimingViol_wen, TimingViol_tckh, TimingViol_tckl, TimingViol_tcycle, TimingViol_tbypass, TimingViol_mask    );


ST_SPHS_2048x8m8_L_OPschlr ST_SPHS_2048x8m8_L_OPschlrinst (Qint, RYint,  Q_gCKint, Q_glitchint,  Q_dataint, RY_rfCKint, RY_rrCKint, RY_frCKint, ICRYint, delTBYPASSint, TBYPASS_D_Qint, TBYPASS_mainint);

defparam ST_SPHS_2048x8m8_L_maininst.Fault_file_name = Fault_file_name;
defparam ST_SPHS_2048x8m8_L_maininst.ConfigFault = ConfigFault;
defparam ST_SPHS_2048x8m8_L_maininst.max_faults = max_faults;
defparam ST_SPHS_2048x8m8_L_maininst.MEM_INITIALIZE = MEM_INITIALIZE;
defparam ST_SPHS_2048x8m8_L_maininst.BinaryInit = BinaryInit;
defparam ST_SPHS_2048x8m8_L_maininst.InitFileName = InitFileName;

endmodule
`endif

`delay_mode_path
`endcelldefine
`disable_portfaults
`nosuppress_faults









/****************************************************************
--  Description         : Verilog Model for SPHSLP cmos65
--  Last modified in    : 5.3.a
--  Date                : April, 2009
--  Last modified by    : SK 
--
****************************************************************/
 

/******************** START OF HEADER****************************
   This Header Gives Information about the parameters & options present in the Model

   words = 1024
   bits  = 8
   mux   = 8 
   
   
   
   

**********************END OF HEADER ******************************/
   


`ifdef slm
        `define functional
`endif
`celldefine
`suppress_faults
`enable_portfaults
`ifdef functional
   `timescale 1ns / 1ns
   `delay_mode_unit
`endif

`ifdef functional

module ST_SPHS_1024x8m8_L (Q, RY,CK, CSN, TBYPASS, WEN, A, D    );

    
    
    parameter 
        Corruption_Read_Violation = 1,
        Fault_file_name = "ST_SPHS_1024x8m8_L_faults.txt",   
        ConfigFault = 0,
        max_faults = 20;
   
   // Parameters for Memory Initialization at 0 ns
    parameter 
        MEM_INITIALIZE = 1'b0,
        BinaryInit     = 1'b0,
        InitFileName   = "ST_SPHS_1024x8m8_L.cde",
        InstancePath = "ST_SPHS_1024x8m8_L",
        Debug_mode = "all_warning_mode";
    
    parameter
        Words = 1024,
        Bits = 8,
        Addr = 10,
        mux = 8;




   
    parameter
        Rows = Words/mux,
        WordX = 8'bx,
        AddrX = 10'bx,
        Word0 = 8'b0,
        X = 1'bx;


         
      
        //  INPUT OUTPUT PORTS
        // ========================
      
	output [Bits-1 : 0] Q;
        
        output RY;   
        
        input [Bits-1 : 0] D;
	input [Addr-1 : 0] A;
	        
        input CK, CSN, TBYPASS, WEN;

        
        
        

           
        
        
	reg [Bits-1 : 0] Qint; 

    
        //  WIRE DECLARATION
        //  =====================
        
        
	wire [Bits-1 : 0] Dint,Mint;
        
        assign Mint=8'b0;
        
	wire [Addr-1 : 0] Aint;
	wire CKint;
	wire CSNint;
	wire WENint;

        
        
        wire TBYPASSint;
        
 
        

        
        wire RYint;
        
        
        assign RY =   RYint; 
        reg RY_outreg, RY_out;
        assign RYint = RY_out;
        
        

        
        
        //  REG DECLARATION
        //  ====================
        
	//Output Register for tbypass
        reg [Bits-1 : 0] tbydata;
        //delayed Output Register
        reg [Bits-1 : 0] delOutReg_data;
        reg [Bits-1 : 0] OutReg_data;   // Data Output register
	reg [Bits-1 : 0] tempMem;
	reg lastCK;
        reg CSNreg;	

        `ifdef slm
        `else
	reg [Bits-1 : 0] Mem [Words-1 : 0]; // RAM array
        `endif
	
	reg [Bits-1 :0] Mem_temp;
	reg ValidAddress;
	reg ValidDebugCode;

        
        
        reg WENreg;
        
        
        /* This register is used to force all warning messages 
        ** OFF during run time.
        ** It is a 2 bit register.
        ** USAGE :
        ** debug_level_off = 2'b00 -> ALL WARNING MESSAGES will be DISPLAYED 
        ** debug_level = 2'b10 -> ALL WARNING MESSAGES will NOT be DISPLAYED.
        ** It will override the value of debug_mode, i.e
        ** if debug_mode = "all_warning_mode", then also
        ** no warning messages will be displayed.     
        ** debug_level = 2'b01 OR 2'b11 -> UNUSED , FOR FUTURE SCALABILITY.
        ** ult, debug_mode will prevail.               
        */ 
         reg [1:0] debug_level;
         reg [8*10: 0] operating_mode;
         reg [8*44: 0] message_status;

        integer d, a, p, i, k, j, l;
        `ifdef slm
           integer MemAddr;
        `endif


        //************************************************************
        //****** CONFIG FAULT IMPLEMENTATION VARIABLES*************** 
        //************************************************************ 

        integer file_ptr, ret_val;
        integer fault_word;
        integer fault_bit;
        integer fcnt, Fault_in_memory;
        integer n, cnt, t;  
        integer FailureLocn [max_faults -1 :0];

        reg [100 : 0] stuck_at;
        reg [200 : 0] tempStr;
        reg [7:0] fault_char;
        reg [7:0] fault_char1; // 8 Bit File Pointer
        reg [Addr -1 : 0] std_fault_word;
        reg [max_faults -1 :0] fault_repair_flag;
        reg [max_faults -1 :0] repair_flag;
        reg [Bits - 1: 0] stuck_at_0fault [max_faults -1 : 0];
        reg [Bits - 1: 0] stuck_at_1fault [max_faults -1 : 0];
        reg [100 : 0] array_stuck_at[max_faults -1 : 0] ; 
        reg msgcnt;
        

        reg [Bits -1 : 0] stuck0;
        reg [Bits -1 : 0] stuck1;

        `ifdef slm
        reg [Bits -1 : 0] slm_temp_data;
        `endif
        

        integer flag_error;
        
        //BUFFER INSTANTIATION
        //=========================
        
        
        assign Q =  Qint; 
        buf bufdata [Bits-1:0] (Dint,D);
        buf bufaddr [Addr-1:0] (Aint,A);
        
	buf (TBYPASSint, TBYPASS);
	buf (CKint, CK);
        
        or (CSNint, CSN,TBYPASSint ); 
	buf (WENint, WEN);
        
        
        
        

           

        

// BEHAVIOURAL MODULE DESCRIPTION
// ================================



task task_insert_faults_in_memory;
begin
   if (ConfigFault)
   begin   
     Fault_in_memory = 1;
     for(i = 0;i< fcnt;i = i+ 1) begin
       if (fault_repair_flag[i] !== 1) begin
         Fault_in_memory = 0;
         if (array_stuck_at[i] === "sa0") begin
         `ifdef slm
            //Read first
            $slm_ReadMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
            //operation
            slm_temp_data = slm_temp_data & stuck_at_0fault[i];
            //write back
            $slm_WriteMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
         `else
            Mem[FailureLocn[i]] = Mem[FailureLocn[i]] & stuck_at_0fault[i];
         `endif
         end //if(array_stuck_at)
                                        
         if(array_stuck_at[i] === "sa1") begin
         `ifdef slm
            //Read first
            $slm_ReadMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
            //operation
            slm_temp_data = slm_temp_data | stuck_at_1fault[i];
            //write back
            $slm_WriteMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
         `else
            Mem[FailureLocn[i]] = Mem[FailureLocn[i]] | stuck_at_1fault[i]; 
         `endif
         end //if(array_stuck_at)
       end   // if(fault_repair_flag
     end    // end of for
   end  
end
endtask


      
task WriteMemX;
begin
   `ifdef slm
   $slm_ResetMemory(MemAddr, WordX);
   `else
    for (i = 0; i < Words; i = i + 1)
       Mem[i] = WordX;
   `endif        
   task_insert_faults_in_memory;
end
endtask

task WriteOutX;                
begin
   OutReg_data = WordX;
end
endtask


task WriteCycle;                  
input [Addr-1 : 0] Address;
reg [Bits-1:0] tempReg1,tempReg2;
integer po,i;
begin
   
   tempReg1 = WordX;
   if (^Address !== X)
   begin
      if (ValidAddress)
      begin
         
         
            `ifdef slm
               $slm_ReadMemoryS(MemAddr, Address, tempReg1);
            `else
               tempReg1 = Mem[Address];
            `endif
                   
            for (po=0;po<Bits;po=po+1)
            begin
               if (Mint[po] === 1'b0)
                  tempReg1[po] = Dint[po];
               else if (Mint[po] === 1'bX)
                  tempReg1[po] = 1'bx;
            end                
         
            `ifdef slm
                $slm_WriteMemory(MemAddr, Address, tempReg1);
            `else
                Mem[Address] = tempReg1;
            `endif
            
      end//if (ValidAddress)
      else
         if(debug_level < 2) $display("%m - %t (MSG_ID 701) WARNING: Address Out Of Range. ",$realtime); 
      task_insert_faults_in_memory;
   end //if (^Address !== X)
   else
   begin
      if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Illegal Value on Address Bus. Memory Corrupted ",$realtime);
      WriteMemX;
      
   end
  
end
endtask

task ReadCycle;
input [Addr-1 : 0] Address;
reg [Bits-1:0] MemData;
integer a;
begin
   if (ValidAddress)
   begin        
      `ifdef slm
         $slm_ReadMemory(MemAddr, Address, MemData);
      `else
         MemData = Mem[Address];
      `endif
   end //if (ValidAddress)  
                
   if(ValidAddress === X)
   begin
      if (Corruption_Read_Violation === 1)
      begin   
         if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Illegal Value on Address Bus. Memory and Output Corrupted ",$realtime);
         WriteMemX;
      end
      else
         if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Illegal Value on Address Bus. Output Corrupted ",$realtime);
      MemData = WordX;
      
   end                        
   else if (ValidAddress === 0)
   begin                        
      if(debug_level < 2) $display("%m - %t (MSG_ID 701) WARNING: Address Out Of Range. Output Corrupted ",$realtime); 
      MemData = WordX;
   end
   
   OutReg_data = MemData;
end
endtask



initial
begin
   // Define format for timing value
  $timeformat (-9, 2, " ns", 0);
  `ifdef slm
  $slm_RegisterMemory(MemAddr, Words, Bits);
  `endif   
  
   debug_level= 2'b0;
   message_status = "All Messages are Switched ON";
  
   
  `ifdef  NO_WARNING_MODE
     debug_level = 2'b10;
     message_status = "All Warning Messages are Switched OFF";
  `endif  
  `ifdef slm
     operating_mode = "SLM";
  `else
     operating_mode = "FUNCTIONAL";
  `endif
if(debug_level !== 2'b10) begin
  $display ("%mINFORMATION ");
  $display ("***************************************");
  $display ("The Model is Operating in %s MODE", operating_mode);
  $display ("%s", message_status);
  if(ConfigFault)
  $display ("Configurable Fault Functionality is ON");   
  else
  $display ("Configurable Fault Functionality is OFF");   
  
  $display ("***************************************");
end     
  if (MEM_INITIALIZE === 1'b1)
  begin   
     `ifdef slm
        if (BinaryInit)
           $slm_LoadMemory(MemAddr, InitFileName, "VERILOG_BIN");
        else
           $slm_LoadMemory(MemAddr, InitFileName, "VERILOG_HEX");

     `else
        if (BinaryInit)
           $readmemb(InitFileName, Mem, 0, Words-1);
        else
           $readmemh(InitFileName, Mem, 0, Words-1);
     `endif
  end   
   
  

  
  RY_out = 1'b1;


        
/*  -----------Implemetation for config fault starts------*/
   msgcnt = X;
   t = 0;
   fault_repair_flag = {max_faults{1'b1}};
   repair_flag = {max_faults{1'b1}};
   if(ConfigFault) 
   begin
      file_ptr = $fopen(Fault_file_name , "r");
      if(file_ptr == 0)
      begin     
          if(debug_level < 3) $display("%m - %t (MSG_ID 201) FAILURE: File cannot be opened ",$realtime);      
      end        
      else                
      begin : read_fault_file
        t = 0;
        for (i = 0; i< max_faults; i= i + 1)
        begin
         
           stuck0 = {Bits{1'b1}};
           stuck1 = {Bits{1'b0}};
           fault_char1 = $fgetc (file_ptr);
           if (fault_char1 == 8'b11111111)
              disable read_fault_file;
           ret_val = $ungetc (fault_char1, file_ptr);
           ret_val = $fgets(tempStr, file_ptr);
           ret_val = $sscanf(tempStr, "%d %d %s",fault_word, fault_bit, stuck_at) ;
           flag_error = 0; 
           if(ret_val !== 0)
           begin         
              if(ret_val == 2 || ret_val == 3)
              begin
                if(ret_val == 2)
                   stuck_at = "sa0";

                if(stuck_at !== "sa0" && stuck_at !== "sa1" && stuck_at !== "none")
                begin
                   if(debug_level < 2) $display("%m - %t (MSG_ID 203) WARNING: Wrong value for stuck at in fault file ",$realtime);
                   flag_error = 1;
                end    
                      
                if(fault_word > Words-1)
                begin
                   if(debug_level < 2) $display("%m - %t (MSG_ID 206) WARNING: Address out of range in fault file ",$realtime);
                   flag_error = 1;
                end    

                if(fault_bit > Bits-1)
                begin  
                   if(debug_level < 2) $display("%m - %t (MSG_ID 205) WARNING: Faulty bit out of range in fault file ",$realtime);
                   flag_error = 1;
                end    

                if(flag_error == 0)
                //Correct Inputs
                begin
                   if(stuck_at === "none")
                   begin
                      if(debug_level < 2) $display("%m - %t (MSG_ID 202) WARNING: No fault injected, empty fault file ",$realtime);
                   end
                   else
                   //Adding the faults
                   begin
                      FailureLocn[t] = fault_word;
                      std_fault_word = fault_word;
                      
                      fault_repair_flag[t] = 1'b0;
                      if (stuck_at === "sa0" )
                      begin
                         stuck0[fault_bit] = 1'b0;         
                         stuck_at_0fault[t] = stuck0;
                      end     
                      if (stuck_at === "sa1" )
                      begin
                         stuck1[fault_bit] = 1'b1;
                         stuck_at_1fault[t] = stuck1; 
                      end

                      array_stuck_at[t] = stuck_at;
                      t = t + 1;
                   end //if(stuck_at === "none")  
                end //if(flag_error == 0)
              end //if(ret_val == 2 || ret_val == 3 
              else
              //wrong number of arguments
              begin
                if(debug_level < 2)
                   $display("%m - %t WARNING :  WRONG VALUES ENTERED FOR FAULTY WORD OR FAULTY BIT OR STUCK_AT IN Fault_file_name", $realtime);
                flag_error = 1;
              end
           end //if(ret_val !== 0)
           else
           begin
              if(debug_level < 2) $display("%m - %t (MSG_ID 202) WARNING: No fault injected, empty fault file ",$realtime);
           end    
        end //for (i = 0; i< m
      end //begin: read_fault_file  
      $fclose (file_ptr);

      fcnt = t;

      
      //fault injection at time 0.
      task_insert_faults_in_memory;
   end // config_fault 
end// initial



//+++++++++++++++++++++++++++++++ CONFIG FAULT IMPLEMETATION ENDS+++++++++++++++++++++++++++++++//
        
always @(CKint)
begin
  
      // Unknown Clock Behaviour
      if (CKint=== X && CSNint !==1)
      begin
         WriteOutX;
         WriteMemX;
          
         RY_out = 1'bX;
      end
      if(CKint === 1'b1 && lastCK === 1'b0)
      begin
         CSNreg = CSNint;
         WENreg = WENint;
         if (CSNint !== 1)
         begin
            if (^Aint === X)
               ValidAddress = X;
            else if (Aint < Words)
               ValidAddress = 1;
            else    
               ValidAddress = 0;

            if (ValidAddress)
	       `ifdef slm
               $slm_ReadMemoryS(MemAddr, Aint, Mem_temp);
               `else        
               Mem_temp = Mem[Aint];
               `endif       
            else
	       Mem_temp = WordX; 
               
            
         end// CSNint !==1...
      end // if(CKint === 1'b1...)
        
   /*---------------------- Normal Read and Write -----------------*/

      if (CSNint !== 1 && CKint === 1'b1 && lastCK === 1'b0 )
      begin
            if (CSNint === 0)
            begin        
               
               if (ValidAddress !== 1'bX )   
                  RY_outreg = ~CKint;
               else
                  RY_outreg = 1'bX;
               if (WENint === 1)
               begin
                  ReadCycle(Aint);
               end
               else if (WENint === 0)
               begin
                  
                   WriteCycle(Aint);
                   
               end
               else if (WENint === X)
               begin
                  // Uncertain write cycle
                  WriteOutX;
                  WriteMemX;
                  
                  RY_outreg = 1'bX;
                  if(debug_level < 2) $display("%m - %t (MSG_ID 002) WARNING: Illegal Value on Write Enable. Memory and Output Corrupted ",$realtime);
                  
               end // if (WENint === X...)
            end //if (CSNint === 0
            else if (CSNint === X)
            begin
                
                RY_outreg = 1'bX;
                if(debug_level < 2) $display("%m - %t (MSG_ID 001) WARNING: Illegal Value on Chip Select. Memory and Output Corrupted ",$realtime);
                WriteOutX;
                WriteMemX;
            end //else if (CSNint === X)
         
       
       
      end // if (CSNint !==1..          

   
   lastCK = CKint;
end // always @(CKint)
        
always @(CSNint)
begin
     // Unknown Clock & CSN signal
     if (CSNint !== 1 && CKint === 1'bx)
     begin
       if(debug_level < 2) $display("%m - %t (MSG_ID 004) WARNING: Chip Select going low while Clock is Invalid. Memory Corrupted ",$realtime);
       WriteMemX;
       WriteOutX;
       
       RY_out = 1'bX;
     end
end



//TBYPASS functionality
 always @(TBYPASSint)
 begin
     
             
      
        OutReg_data = WordX;
        if(TBYPASSint === 1'b1) 
          tbydata = Dint;
        else
          tbydata = WordX;
          
    
    
    
 end //end of always TBYPASSint

 always @(Dint)
 begin
    
     
       
      if(TBYPASSint === 1'b1)
        tbydata = Dint;
      
    
    
    
 end //end of always Dint

//assign output data
always @(OutReg_data)
   #1 delOutReg_data = OutReg_data;

always @(delOutReg_data or tbydata or TBYPASSint)
   if(TBYPASSint === 1'b0)
      Qint = delOutReg_data;
   else if(TBYPASSint === 1'bX)
      Qint = WordX;
   else
      Qint = tbydata;      

 
 always @(TBYPASSint)
 begin
    
     
      
      if(TBYPASSint !== 1'b0)
        RY_outreg = 1'bx;
        
    
    
    
 end

 always @(negedge CKint)
 begin
    
     
      
      if(TBYPASSint === 1'b1)
        RY_outreg = 1'b1;
      else if (TBYPASSint === 1'b0) 
         if(CSNreg === 1'b0 && WENreg !== 1'bX && ValidAddress !== 1'bX  && RY_outreg !== 1'bX)
            RY_outreg = ~CKint;
            
    
    
    
 end

always @(RY_outreg)
begin
  #1 RY_out = RY_outreg;
end





endmodule


`else

`timescale 1ns / 1ps
`delay_mode_path
 
module ST_SPHS_1024x8m8_L_main (Q_glitch,  Q_data, Q_gCK , RY_rfCK, RY_rrCK, RY_frCK, ICRY, delTBYPASS, TBYPASS_D_Q, TBYPASS_main, CK,  CSN, TBYPASS, WEN,  A, D, M,debug_level , TimingViol_addr, TimingViol_data, TimingViol_csn, TimingViol_wen, TimingViol_tckh, TimingViol_tckl, TimingViol_tcycle, TimingViol_tbypass, TimingViol_mask     );

    
       
    parameter 
        Corruption_Read_Violation = 1,
        Fault_file_name = "ST_SPHS_1024x8m8_L_faults.txt",   
        ConfigFault = 0,
        max_faults = 20;
   
    // Parameters for Memory Initialization at 0 ns
    parameter 
        MEM_INITIALIZE = 1'b0,
        BinaryInit     = 1'b0,
        InitFileName   = "ST_SPHS_1024x8m8_L.cde",
        InstancePath = "ST_SPHS_1024x8m8_L",
        Debug_mode = "all_warning_mode";
    
    parameter
        Words = 1024,
        Bits = 8,
        Addr = 10,
        mux = 8,
        Rows = Words/mux;




   
    parameter
        WordX = 8'bx,
        AddrX = 10'bx,
        Word0 = 8'b0,
        X = 1'bx;
         
      
        //  INPUT OUTPUT PORTS
        // ========================
	output [Bits-1 : 0] Q_glitch;
	output [Bits-1 : 0] Q_data;
	output [Bits-1 : 0] Q_gCK;
        
        output ICRY;
        output RY_rfCK;
	output RY_rrCK;
	output RY_frCK;   
	output [Bits-1 : 0] delTBYPASS; 
	output TBYPASS_main; 
        output [Bits-1 : 0] TBYPASS_D_Q;
        
        input [Bits-1 : 0] D,M;
	input [Addr-1 : 0] A;
	input CK, CSN, TBYPASS, WEN;
        input [1 : 0] debug_level;

	input [Bits-1 : 0] TimingViol_data, TimingViol_mask;
	input TimingViol_addr, TimingViol_csn, TimingViol_wen, TimingViol_tckh, TimingViol_tckl, TimingViol_tcycle, TimingViol_tbypass;

        
        
 



        
        wire [Bits-1 : 0] Dint,Mint; 
	wire [Addr-1 : 0] Aint;
	wire CKint;
	wire CSNint;
	wire WENint;
        
        


        
        
        
	wire  Mreg_0;
	wire  Mreg_1;
	wire  Mreg_2;
	wire  Mreg_3;
	wire  Mreg_4;
	wire  Mreg_5;
	wire  Mreg_6;
	wire  Mreg_7;
	
	reg [Bits-1 : 0] OutReg_glitch; // Glitch Output register
	reg [Bits-1 : 0] OutReg_data;   // Data Output register
	reg [Bits-1 : 0] Dreg,Mreg;
	reg [Bits-1 : 0] Mreg_temp;
	reg [Bits-1 : 0] tempMem;
	reg [Bits-1 : 0] prevMem;
	reg [Addr-1 : 0] Areg;
	reg [Bits-1 : 0] Q_gCKreg; 
	reg [Bits-1 : 0] lastQ_gCK;
	reg [Bits-1 : 0] last_Qdata;
	reg lastCK, CKreg;
	reg CSNreg;
	reg WENreg;
	
        reg [Bits-1 : 0] TimingViol_data_last;
        reg [Bits-1 : 0] TimingViol_mask_last;
	
	reg [Bits-1 : 0] Mem [Words-1 : 0]; // RAM array
	
	reg [Bits-1 :0] Mem_temp;
	reg ValidAddress;
	reg ValidDebugCode;
	reg ICGFlag;
        



        
       
        
        
        

        integer d, a, p, i, k, j, l;

        //************************************************************
        //****** CONFIG FAULT IMPLEMENTATION VARIABLES*************** 
        //************************************************************ 

        integer file_ptr, ret_val;
        integer fault_word;
        integer fault_bit;
        integer fcnt, Fault_in_memory;
        integer n, cnt, t;  
        integer FailureLocn [max_faults -1 :0];

        reg [100 : 0] stuck_at;
        reg [200 : 0] tempStr;
        reg [7:0] fault_char;
        reg [7:0] fault_char1; // 8 Bit File Pointer
        reg [Addr -1 : 0] std_fault_word;
        reg [max_faults -1 :0] fault_repair_flag;
        reg [max_faults -1 :0] repair_flag;
        reg [Bits - 1: 0] stuck_at_0fault [max_faults -1 : 0];
        reg [Bits - 1: 0] stuck_at_1fault [max_faults -1 : 0];
        reg [100 : 0] array_stuck_at[max_faults -1 : 0] ; 
        reg msgcnt;
        

        reg [Bits -1 : 0] stuck0;
        reg [Bits -1 : 0] stuck1;

        integer flag_error;


	assign Mreg_0 = Mreg[0];
	assign Mreg_1 = Mreg[1];
	assign Mreg_2 = Mreg[2];
	assign Mreg_3 = Mreg[3];
	assign Mreg_4 = Mreg[4];
	assign Mreg_5 = Mreg[5];
	assign Mreg_6 = Mreg[6];
	assign Mreg_7 = Mreg[7];

        //BUFFER INSTANTIATION
        //=========================
        
        buf bufdint [Bits-1:0] (Dint, D);

        buf bufmint [Bits-1:0] (Mint, M);
        
        buf bufaint [Addr-1:0] (Aint, A);
	
	buf (TBYPASS_main, TBYPASS);
	buf (CKint, CK);
        
        buf (CSNint, CSN); 
	buf (WENint, WEN);

        //TBYPASS functionality
        buf bufdeltb [Bits-1:0] (delTBYPASS, TBYPASS);
        
           
        buf bugtbdq [Bits-1:0] (TBYPASS_D_Q, D);

        
        


        
        
        

        wire RY_rfCKint, RY_rrCKint, RY_frCKint, ICRYFlagint;
        reg RY_rfCKreg, RY_rrCKreg, RY_frCKreg; 
	reg InitialRYFlag, ICRYFlag;
        
        buf (RY_rfCK, RY_rfCKint);
	buf (RY_rrCK, RY_rrCKint);
	buf (RY_frCK, RY_frCKint); 
        
        buf (ICRY, ICRYFlagint);
        assign ICRYFlagint = ICRYFlag;
        
        
    specify
        specparam

            tdq = 0.01,
            ttmq = 0.01,
            
            taa_ry = 1.0,
            th_ry = 0.9,
            tck_ry = 1.0,
            taa = 1.0,
            th = 0.9;
        /*-------------------- Propagation Delays ------------------*/
	if (WENreg && !ICGFlag) (CK *> (Q_data[0] : D[0])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[1] : D[1])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[2] : D[2])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[3] : D[3])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[4] : D[4])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[5] : D[5])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[6] : D[6])) = (taa, taa);
	if (WENreg && !ICGFlag) (CK *> (Q_data[7] : D[7])) = (taa, taa);

	if (!ICGFlag) (CK *> (Q_glitch[0] : D[0])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[1] : D[1])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[2] : D[2])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[3] : D[3])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[4] : D[4])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[5] : D[5])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[6] : D[6])) = (th, th);
	if (!ICGFlag) (CK *> (Q_glitch[7] : D[7])) = (th, th);

	if (!ICGFlag) (CK *> (Q_gCK[0] : D[0])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[1] : D[1])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[2] : D[2])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[3] : D[3])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[4] : D[4])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[5] : D[5])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[6] : D[6])) = (th, th);
	if (!ICGFlag) (CK *> (Q_gCK[7] : D[7])) = (th, th);

	if (!TBYPASS) (TBYPASS *> delTBYPASS[0]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[1]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[2]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[3]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[4]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[5]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[6]) = (0);
	if (!TBYPASS) (TBYPASS *> delTBYPASS[7]) = (0);
	if (TBYPASS) (TBYPASS *> delTBYPASS[0]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[1]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[2]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[3]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[4]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[5]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[6]) = (ttmq);
	if (TBYPASS) (TBYPASS *> delTBYPASS[7]) = (ttmq);
      (D[0] *> TBYPASS_D_Q[0]) = (tdq, tdq);
      (D[1] *> TBYPASS_D_Q[1]) = (tdq, tdq);
      (D[2] *> TBYPASS_D_Q[2]) = (tdq, tdq);
      (D[3] *> TBYPASS_D_Q[3]) = (tdq, tdq);
      (D[4] *> TBYPASS_D_Q[4]) = (tdq, tdq);
      (D[5] *> TBYPASS_D_Q[5]) = (tdq, tdq);
      (D[6] *> TBYPASS_D_Q[6]) = (tdq, tdq);
      (D[7] *> TBYPASS_D_Q[7]) = (tdq, tdq);


        // RY functionality
	if (!ICRY && InitialRYFlag) (CK *> RY_rfCK) = (th_ry, th_ry);
	if (!ICRY && InitialRYFlag) (CK *> RY_rrCK) = (taa_ry, taa_ry);
	if (!ICRY && InitialRYFlag) (CK *> RY_frCK) = (tck_ry, tck_ry);   

	endspecify


assign #0 Q_data = OutReg_data;
assign Q_glitch = OutReg_glitch; 
assign Q_gCK = Q_gCKreg;

    // BEHAVIOURAL MODULE DESCRIPTION



task task_insert_faults_in_memory;
begin
   if (ConfigFault)
   begin   
     Fault_in_memory = 1;
     for(i = 0;i< fcnt;i = i+ 1) begin
       if (fault_repair_flag[i] !== 1) begin
         Fault_in_memory = 0;
         if (array_stuck_at[i] === "sa0") begin
         `ifdef slm
            //Read first
            $slm_ReadMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
            //operation
            slm_temp_data = slm_temp_data & stuck_at_0fault[i];
            //write back
            $slm_WriteMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
         `else
            Mem[FailureLocn[i]] = Mem[FailureLocn[i]] & stuck_at_0fault[i];
         `endif
         end //if(array_stuck_at)
                                        
         if(array_stuck_at[i] === "sa1") begin
         `ifdef slm
            //Read first
            $slm_ReadMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
            //operation
            slm_temp_data = slm_temp_data | stuck_at_1fault[i];
            //write back
            $slm_WriteMemoryS(MemAddr, FailureLocn[i], slm_temp_data);
         `else
            Mem[FailureLocn[i]] = Mem[FailureLocn[i]] | stuck_at_1fault[i]; 
         `endif
         end //if(array_stuck_at)
       end   // if(fault_repair_flag
     end    // end of for
   end  
end
endtask



task chstate;
   input [Bits-1 : 0] clkin;
   output [Bits-1 : 0] clkout;
   integer d;
begin
   if ( $realtime != 0 )
      for (d = 0; d < Bits; d = d + 1)
      begin
         if (clkin[d] === 1'b0)
            clkout[d] = 1'b1;
         else if (clkin[d] === 1'b1)
            clkout[d] = 1'bx;
         else
            clkout[d] = 1'b0;
      end
end
endtask


task WriteMemX;
begin
   for (i = 0; i < Words; i = i + 1)
       Mem[i] = WordX;
   task_insert_faults_in_memory;
end
endtask

task WriteLocMskX_bwise;
   input [Addr-1 : 0] Address;
   input [Bits-1 : 0] Mask;
begin
   if (^Address !== X)
   begin
      tempMem = Mem[Address];
             
      for (j = 0;j< Bits; j=j+1)
         if (Mask[j] === 1'bx)
            tempMem[j] = 1'bx;
                    
      Mem[Address] = tempMem;
      task_insert_faults_in_memory;
   end//if (^Address !== X
   else
      WriteMemX;
end
endtask
    
task WriteOutX;                
begin
   OutReg_data= WordX;
   OutReg_glitch= WordX;
end
endtask

task WriteCycle;                  
   input [Addr-1 : 0] Address;
   reg [Bits-1:0] tempReg1,tempReg2;
   integer po,i;
begin
  
   tempReg1 = WordX;
   if (^Address !== X)
   begin
      if (ValidAddress)
      begin
         
             tempReg1 = Mem[Address];
             for (po=0;po<Bits;po=po+1)
                if (Mreg[po] === 1'b0)
                   tempReg1[po] = Dreg[po];
                else if (Mreg[po] === 1'bX)
                    tempReg1[po] = 1'bx;
                        
                Mem[Address] = tempReg1;
                     
      end //if (ValidAddress)
      else
         if(debug_level < 2) $display("%m - %t (MSG_ID 701) WARNING: Write Port:  Address Out Of Range. ",$realtime);
      task_insert_faults_in_memory;
   end//if (^Address !== X)
   else
   begin
      if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Write Port:  Illegal Value on Address Bus. Memory Corrupted ",$realtime);
      WriteMemX;
      
   end
   
end
endtask

task ReadCycle;
   input [Addr-1 : 0] Address;
   reg [Bits-1:0] MemData;
   integer a;
begin

   if (ValidAddress)
      MemData = Mem[Address];

   if(ValidAddress === X)
   begin
      if(debug_level < 2) $display("%m - %t (MSG_ID 008) WARNING: Read Port:  Illegal Value on Address Bus. Memory and Output Corrupted ",$realtime);
      MemData = WordX;
      WriteMemX;
      
   end                        
   else if (ValidAddress === 0)
   begin                        
      if(debug_level < 2) $display("%m - %t (MSG_ID 701) WARNING: Read Port:  Address Out Of Range. Output Corrupted ",$realtime);
      MemData = WordX;
   end

   for (a = 0; a < Bits; a = a + 1)
   begin
      if (MemData[a] !== OutReg_data[a])
         OutReg_glitch[a] = WordX[a];
      else
         OutReg_glitch[a] = MemData[a];
   end//for (a = 0; a <

   OutReg_data = MemData;
   last_Qdata = Q_data;

end
endtask




assign RY_rfCKint = RY_rfCKreg;
assign RY_frCKint = RY_frCKreg;
assign RY_rrCKint = RY_rrCKreg;

// Define format for timing value
initial
begin
   $timeformat (-9, 2, " ns", 0);
   ICGFlag = 0;

   //Initialize Memory
   if (MEM_INITIALIZE === 1'b1)
   begin   
      if (BinaryInit)
         $readmemb(InitFileName, Mem, 0, Words-1);
      else
         $readmemh(InitFileName, Mem, 0, Words-1);
   end

   
   ICRYFlag = 1;
   InitialRYFlag = 0;
   ICRYFlag <= 0;
   RY_rfCKreg = 1'b1;
   RY_rrCKreg = 1'b1;
   RY_frCKreg = 1'b1;

   
   

/*  -----------Implementation for config fault starts------*/
   msgcnt = X;
   t = 0;
   fault_repair_flag = {max_faults{1'b1}};
   repair_flag = {max_faults{1'b1}};
   if(ConfigFault) 
   begin
      file_ptr = $fopen(Fault_file_name , "r");
      if(file_ptr == 0)
      begin     
          if(debug_level < 3) $display("%m - %t (MSG_ID 201) FAILURE: File cannot be opened ",$realtime);      
      end        
      else                
      begin : read_fault_file
        t = 0;
        for (i = 0; i< max_faults; i= i + 1)
        begin
         
           stuck0 = {Bits{1'b1}};
           stuck1 = {Bits{1'b0}};
           fault_char1 = $fgetc (file_ptr);
           if (fault_char1 == 8'b11111111)
              disable read_fault_file;
           ret_val = $ungetc (fault_char1, file_ptr);
           ret_val = $fgets(tempStr, file_ptr);
           ret_val = $sscanf(tempStr, "%d %d %s",fault_word, fault_bit, stuck_at) ;
           flag_error = 0; 
           if(ret_val !== 0)
           begin         
              if(ret_val == 2 || ret_val == 3)
              begin
                if(ret_val == 2)
                   stuck_at = "sa0";

                if(stuck_at !== "sa0" && stuck_at !== "sa1" && stuck_at !== "none")
                begin
                   if(debug_level < 2) $display("%m - %t (MSG_ID 203) WARNING: Wrong value for stuck at in fault file ",$realtime);
                   flag_error = 1;
                end    
                      
                if(fault_word > Words-1)
                begin
                   if(debug_level < 2) $display("%m - %t (MSG_ID 206) WARNING: Address out of range in fault file ",$realtime);
                   flag_error = 1;
                end    

                if(fault_bit > Bits-1)
                begin  
                   if(debug_level < 2) $display("%m - %t (MSG_ID 205) WARNING: Faulty bit out of range in fault file ",$realtime);
                   flag_error = 1;
                end    

                if(flag_error == 0)
                //Correct Inputs
                begin
                   if(stuck_at === "none")
                   begin
                      if(debug_level < 2) $display("%m - %t (MSG_ID 202) WARNING: No fault injected, empty fault file ",$realtime);
                   end
                   else
                   //Adding the faults
                   begin
                      FailureLocn[t] = fault_word;
                      std_fault_word = fault_word;
                      
                      fault_repair_flag[t] = 1'b0;
                      if (stuck_at === "sa0" )
                      begin
                         stuck0[fault_bit] = 1'b0;         
                         stuck_at_0fault[t] = stuck0;
                      end     
                      if (stuck_at === "sa1" )
                      begin
                         stuck1[fault_bit] = 1'b1;
                         stuck_at_1fault[t] = stuck1; 
                      end

                      array_stuck_at[t] = stuck_at;
                      t = t + 1;
                   end //if(stuck_at === "none")  
                end //if(flag_error == 0)
              end //if(ret_val == 2 || ret_val == 3 
              else
              //wrong number of arguments
              begin
                if(debug_level < 2)
                   $display("%m - %t WARNING :  WRONG VALUES ENTERED FOR FAULTY WORD OR FAULTY BIT OR STUCK_AT IN Fault_file_name", $realtime);
                flag_error = 1;
              end
           end //if(ret_val !== 0)
           else
           begin
              if(debug_level < 2) $display("%m - %t (MSG_ID 202) WARNING: No fault injected, empty fault file ",$realtime);
           end    
        end //for (i = 0; i< m
      end //begin: read_fault_file  
      $fclose (file_ptr);

      fcnt = t;
      
      task_insert_faults_in_memory;
   end // config_fault 
end// initial



//+++++++++++++++++++++++++++++++ CONFIG FAULT IMPLEMETATION ENDS+++++++++++++++++++++++++++++++//

always @(CKint)
begin
   lastCK = CKreg;
   CKreg = CKint;
   
   if (CKint !== 0 && CSNint !== 1)
   begin
     InitialRYFlag = 1;
   end
   
      // Unknown Clock Behaviour
      if (((CKint=== X && CSNint !==1) || (CKint=== X && CSNreg !==1 && lastCK ===1)))
      begin
         
         ICRYFlag = 1;   
         chstate(Q_gCKreg, Q_gCKreg);
	 WriteOutX;
         WriteMemX;
      end//if (((CKint===
                
   
   if (CKint===1 && lastCK ===0 && CSNint === X  )
       ICRYFlag = 1;
   else if (CKint === 1 && lastCK === 0 && CSNint === 0 )
       ICRYFlag = 0;
   

   /*---------------------- Latching signals ----------------------*/
   if(CKreg === 1'b1 && lastCK === 1'b0)
   begin
      if (CSNint !== 1)
      begin
         ICGFlag = 0;
         Dreg = Dint;
         Mreg = Mint;
         WENreg = WENint;
         Areg = Aint;
         if (^Areg === X)
            ValidAddress = X;
         else if (Areg < Words)
            ValidAddress = 1;
         else
            ValidAddress = 0;

         if (ValidAddress)
            Mem_temp = Mem[Aint];
         else
            Mem_temp = WordX; 

         
      end//if (CSNint !== 1)
         
      CSNreg = CSNint;
      last_Qdata = Q_data;
      
      
   end//if(CKreg === 1'b1 && lastCK =   
     
   /*---------------------- Normal Read and Write -----------------*/

   if ((CSNreg !== 1) && (CKreg === 1 && lastCK === 0))
   begin
      if (WENreg === 1'b1 && CSNreg === 1'b0)
      begin
         ReadCycle(Areg);
         chstate(Q_gCKreg, Q_gCKreg);
      end//if (WENreg === 1 && C
      else if (WENreg === 0 && CSNreg === 0)
      begin
          
           WriteCycle(Areg);
           
      end
      /*---------- Corruption due to faulty values on signals --------*/
      else if (CSNreg === 1'bX)
      begin
         // Uncertain cycle
         if(debug_level < 2) $display("%m - %t (MSG_ID 001) WARNING: Illegal Value on Chip Select. Memory and Output Corrupted ",$realtime);
         WriteMemX;
         WriteOutX;
         chstate(Q_gCKreg, Q_gCKreg);
      end//else if (CSN === 1'bX
      else if (WENreg === X)
      begin
         // Uncertain write cycle
         if(debug_level < 2) $display("%m - %t (MSG_ID 002) WARNING: Illegal Value on Write Enable. Memory and Output Corrupted ",$realtime);
         WriteMemX;
         WriteOutX;
         chstate(Q_gCKreg, Q_gCKreg);
         
         ICRYFlag = 1;
         
      end//else if (WENreg ===
      
      

   end //if ((CSNreg !== 1) && (CKreg    
   
end // always @(CKint)

always @(CSNint)
begin   
     // Unknown Clock & CSN signal
     if (CSNint !== 1 && CKint === X )
     begin
       if(debug_level < 2) $display("%m - %t (MSG_ID 003) WARNING: Illegal Value on Clock. Memory and Output Corrupted ",$realtime);
       chstate(Q_gCKreg, Q_gCKreg);
       WriteMemX;
       WriteOutX;
       
       ICRYFlag = 1;
     end//if (CSNint !== 1
end      


 always @(TBYPASS_main)
 begin
 
      if (TBYPASS_main !== 0)
        
        ICRYFlag = 1;
      OutReg_data = WordX;
      OutReg_glitch = WordX;
    
 end


  

        /*---------------RY Functionality-----------------*/
always @(posedge CKreg)
begin

     
     if ((CSNreg === 0) && (CKreg === 1 && lastCK === 0) && TBYPASS_main === 1'b0)
     begin
       if (WENreg !== 1'bX && ValidAddress !== 1'bX)
       begin
         RY_rfCKreg = ~RY_rfCKreg;
         RY_rrCKreg = ~RY_rrCKreg;
       end
       else
         ICRYFlag = 1'b1; 
     end
     
     
end

 always @(negedge CKreg)
 begin
 
      
      if (TBYPASS_main === 1'b1)
      begin
        RY_frCKreg = ~RY_frCKreg;
        ICRYFlag = 1'b0;
      end  
      else if (TBYPASS_main === 1'b0 && (CSNreg === 0) && (CKreg === 0 && lastCK === 1))
      begin
        if (WENreg !== 1'bX && ValidAddress !== 1'bX)
           RY_frCKreg = ~RY_frCKreg;
      end
      
     
     
   
 end

always @ (TimingViol_tckl or TimingViol_tcycle or TimingViol_csn or TimingViol_tckh or TimingViol_tbypass or TimingViol_wen or TimingViol_addr  )
ICRYFlag = 1;
        /*---------------------------------*/





/*---------------TBYPASS  Functionality in functional model -----------------*/

always @(TimingViol_data)
// tds or tdh violation
begin
#0
   for (l = 0; l < Bits; l = l + 1)
   begin   
      if((TimingViol_data[l] !== TimingViol_data_last[l]))
         Mreg[l] = 1'bx;
   end   
   WriteLocMskX_bwise(Areg,Mreg);
   TimingViol_data_last = TimingViol_data;
end


        
/*---------- Corruption due to Timing Violations ---------------*/

always @(TimingViol_tckl or TimingViol_tcycle)
// tckl -  tcycle
begin
#0
   WriteOutX;
   #0.00 WriteMemX;
end

always @(TimingViol_csn)
// tps or tph
begin
#0
   CSNreg = 1'bX;
   WriteOutX;
   WriteMemX;  
   if (CSNreg === 1)
   begin
      chstate(Q_gCKreg, Q_gCKreg);
   end
end

always @(TimingViol_tckh)
// tckh
begin
#0
   ICGFlag = 1;
   chstate(Q_gCKreg, Q_gCKreg);
   WriteOutX;
   WriteMemX;
end

always @(TimingViol_addr)
// tas or tah
begin
#0
   if (WENreg !== 0)
      WriteOutX;
   WriteMemX;
   
end


always @(TimingViol_wen)
//tws or twh
begin
#0
   WriteMemX; 
   WriteOutX;
end


always @(TimingViol_tbypass)
//ttmck
begin
#0
   WriteOutX;
   WriteMemX;  
end







endmodule

module ST_SPHS_1024x8m8_L_OPschlr (QINT,  RYINT, Q_gCK, Q_glitch,  Q_data, RY_rfCK, RY_rrCK, RY_frCK, ICRY, delTBYPASS, TBYPASS_D_Q, TBYPASS_main);

    parameter
        Words = 1024,
        Bits = 8,
        Addr = 10;
        

    parameter
        WordX = 8'bx,
        AddrX = 10'bx,
        X = 1'bx;

	output [Bits-1 : 0] QINT;
	input [Bits-1 : 0] Q_glitch;
	input [Bits-1 : 0] Q_data;
	input [Bits-1 : 0] Q_gCK;
        input [Bits-1 : 0] TBYPASS_D_Q;
        input [Bits-1 : 0] delTBYPASS;
        input TBYPASS_main;
	
	integer m,a, d, n, o, p;
	wire [Bits-1 : 0] QINTint;
	wire [Bits-1 : 0] QINTERNAL;

        reg [Bits-1 : 0] OutReg;
	reg [Bits-1 : 0] lastQ_gCK, Q_gCKreg;
	reg [Bits-1 : 0] lastQ_data, Q_datareg;
	reg [Bits-1 : 0] QINTERNALreg;
	reg [Bits-1 : 0] lastQINTERNAL;

buf bufqint [Bits-1:0] (QINT, QINTint);

	assign QINTint[0] = (TBYPASS_main===0 && delTBYPASS[0]===0)?OutReg[0] : (TBYPASS_main===1 && delTBYPASS[0]===1)?TBYPASS_D_Q[0] : WordX;
	assign QINTint[1] = (TBYPASS_main===0 && delTBYPASS[1]===0)?OutReg[1] : (TBYPASS_main===1 && delTBYPASS[1]===1)?TBYPASS_D_Q[1] : WordX;
	assign QINTint[2] = (TBYPASS_main===0 && delTBYPASS[2]===0)?OutReg[2] : (TBYPASS_main===1 && delTBYPASS[2]===1)?TBYPASS_D_Q[2] : WordX;
	assign QINTint[3] = (TBYPASS_main===0 && delTBYPASS[3]===0)?OutReg[3] : (TBYPASS_main===1 && delTBYPASS[3]===1)?TBYPASS_D_Q[3] : WordX;
	assign QINTint[4] = (TBYPASS_main===0 && delTBYPASS[4]===0)?OutReg[4] : (TBYPASS_main===1 && delTBYPASS[4]===1)?TBYPASS_D_Q[4] : WordX;
	assign QINTint[5] = (TBYPASS_main===0 && delTBYPASS[5]===0)?OutReg[5] : (TBYPASS_main===1 && delTBYPASS[5]===1)?TBYPASS_D_Q[5] : WordX;
	assign QINTint[6] = (TBYPASS_main===0 && delTBYPASS[6]===0)?OutReg[6] : (TBYPASS_main===1 && delTBYPASS[6]===1)?TBYPASS_D_Q[6] : WordX;
	assign QINTint[7] = (TBYPASS_main===0 && delTBYPASS[7]===0)?OutReg[7] : (TBYPASS_main===1 && delTBYPASS[7]===1)?TBYPASS_D_Q[7] : WordX;
assign QINTERNAL = QINTERNALreg;

always @ (TBYPASS_main)
begin
if (TBYPASS_main === 0 || TBYPASS_main === X) 
     QINTERNALreg = WordX;
end


        
/*------------------ RY functionality -----------------*/
       output RYINT;
        input RY_rfCK, RY_rrCK, RY_frCK, ICRY;
        wire RYINTint;
        reg RYINTreg, RYRiseFlag;

        buf (RYINT, RYINTint);

assign RYINTint = RYINTreg;
        
initial
begin
   RYRiseFlag = 1'b0;
   RYINTreg = 1'b1;
end

always @(ICRY)
begin
   if($realtime == 0)
      RYINTreg = 1'b1;
   else
      RYINTreg = 1'bx;
end

always @(RY_rfCK)
   if (ICRY !== 1)
   begin
      if ($realtime != 0)
      begin   
         RYINTreg = 0;
         RYRiseFlag=0;
      end   
   end


always @(RY_rrCK) 
#0 
   if (ICRY !== 1 && $realtime != 0)
   begin
      if (RYRiseFlag === 0)
      begin
         RYRiseFlag=1;
      end
      else
      begin
         RYINTreg = 1'b1;
         RYRiseFlag=0;
      end
   end


always @(RY_frCK)         
   if (ICRY !== 1 && $realtime != 0)
   begin
      if (RYRiseFlag === 0)
      begin
         RYRiseFlag=1;
      end
      else
      begin
         RYINTreg = 1'b1;
         RYRiseFlag=0;
      end
   end   

/*------------------------------------------------ */

always @(Q_gCK)
begin
#0  //This has been used for removing races during hold time vilations in MODELSIM simulator.
   lastQ_gCK = Q_gCKreg;
   Q_gCKreg <= Q_gCK;
   for (m = 0; m < Bits; m = m + 1)
   begin
      if (lastQ_gCK[m] !== Q_gCK[m])
      begin
        lastQINTERNAL[m] = QINTERNALreg[m];
        QINTERNALreg[m] = Q_glitch[m];
      end
   end
end

always @(Q_data)
begin
#0  //This has been used for removing races during hold time vilations in MODELSIM simulator.
    lastQ_data = Q_datareg;
    Q_datareg <= Q_data;
    for (n = 0; n < Bits; n = n + 1)
    begin
      if (lastQ_data[n] !== Q_data[n])
      begin
       	lastQINTERNAL[n] = QINTERNALreg[n];
        QINTERNALreg[n] = Q_data[n];
      end
    end
end

always @(QINTERNAL)
begin
   for (d = 0; d < Bits; d = d + 1)
   begin
      if (OutReg[d] !== QINTERNAL[d])
         OutReg[d] = QINTERNAL[d];
   end
end



endmodule



module ST_SPHS_1024x8m8_L (Q, RY, CK, CSN, TBYPASS, WEN,  A,  D   );


    parameter 
        Corruption_Read_Violation = 1,
        Fault_file_name = "ST_SPHS_1024x8m8_L_faults.txt",   
        ConfigFault = 0,
        max_faults = 20;
   
    // Parameters for Memory Initialization at 0 ns
    parameter 
        MEM_INITIALIZE = 1'b0,
        BinaryInit     = 1'b0,
        InitFileName   = "ST_SPHS_1024x8m8_L.cde",
        InstancePath = "ST_SPHS_1024x8m8_L",
        Debug_mode = "all_warning_mode";
    
    parameter
        Words = 1024,
        Bits = 8,
        Addr = 10,
        mux = 8;




   
    parameter
        Rows = Words/mux,
        WordX = 8'bx,
        AddrX = 10'bx,
        Word0 = 8'b0,
        X = 1'bx;

        
         
    // INPUT OUTPUT PORTS
    //  ======================

    output [Bits-1 : 0] Q;
    
    output RY;   
    input CK;
    input CSN;
    input WEN;
    input TBYPASS;
    input [Addr-1 : 0] A;
    input [Bits-1 : 0] D;
    
    


   

     

   // WIRE DECLARATIONS
   //======================
   
   wire [Bits-1 : 0] Q_glitchint;
   wire [Bits-1 : 0] Q_dataint;
   wire [Bits-1 : 0] Dint,Mint;
   wire [Addr-1 : 0] Aint;
   wire [Bits-1 : 0] Q_gCKint;
   wire CKint;
   wire CSNint;
   wire WENint;
   wire TBYPASSint;
   wire TBYPASS_mainint;
   wire [Bits-1 : 0]  TBYPASS_D_Qint;
   wire [Bits-1 : 0]  delTBYPASSint;




   wire [Bits-1 : 0] Qint, Q_out;
   
   
   

   //REG DECLARATIONS
   //======================

   reg [Bits-1 : 0] Dreg,Mreg;
   reg [Addr-1 : 0] Areg;
   reg CKreg;
   reg CSNreg;
   reg WENreg;
	
   reg [Bits-1 : 0] TimingViol_data, TimingViol_mask;
   reg [Bits-1 : 0] TimingViol_data_last, TimingViol_mask_last;
	reg TimingViol_data_0, TimingViol_mask_0;
	reg TimingViol_data_1, TimingViol_mask_1;
	reg TimingViol_data_2, TimingViol_mask_2;
	reg TimingViol_data_3, TimingViol_mask_3;
	reg TimingViol_data_4, TimingViol_mask_4;
	reg TimingViol_data_5, TimingViol_mask_5;
	reg TimingViol_data_6, TimingViol_mask_6;
	reg TimingViol_data_7, TimingViol_mask_7;
   reg TimingViol_addr;
   reg TimingViol_csn, TimingViol_wen, TimingViol_tbypass;
   reg TimingViol_tckh, TimingViol_tckl, TimingViol_tcycle;
   




   wire [Bits-1 : 0] MEN,CSWEMTBYPASS;
   wire CSTBYPASSN, CSWETBYPASSN,CS;

   /* This register is used to force all warning messages 
   ** OFF during run time.
   ** 
   */ 
   reg [1:0] debug_level;
   reg [8*10: 0] operating_mode;
   reg [8*44: 0] message_status;


initial
begin
  debug_level = 2'b0;
  message_status = "All Messages are Switched ON";
    
  
  `ifdef  NO_WARNING_MODE
     debug_level = 2'b10;
     message_status = "All Messages are Switched OFF"; 
  `endif 
if(debug_level !== 2'b10) begin
   $display ("%m  INFORMATION");
   $display ("***************************************");
   $display ("The Model is Operating in TIMING MODE");
   $display ("Please make sure that SDF is properly annotated otherwise dummy values will be used");
   $display ("%s", message_status);
   if(ConfigFault)
   $display ("Configurable Fault Functionality is ON");   
   else
   $display ("Configurable Fault Functionality is OFF");
   
   $display ("***************************************");
end     
end     

   
   // BUF DECLARATIONS
   //=====================
   
   buf (CKint, CK);
   or (CSNint, CSN, TBYPASSint);
   buf (TBYPASSint, TBYPASS);
   buf (WENint, WEN);
   buf bufDint [Bits-1:0] (Dint, D);
   
   assign Mint = 8'b0;
   
   buf bufAint [Addr-1:0] (Aint, A);


   assign Q =  Qint;




   


    wire  RYint, RY_rfCKint, RY_rrCKint, RY_frCKint, RY_out;
    reg RY_outreg; 
    assign RY_out = RY_outreg;
    assign RY =   RY_out;
    always @ (RYint)
    begin
       RY_outreg = RYint;
    end

        
    // Only include timing checks during behavioural modelling


    
    assign CS =  CSN;
    or (CSWETBYPASSN, WENint, CSNint);
    or (CSNTBY, CSN, TBYPASSint);  


        
 or (CSWEMTBYPASS[0], Mint[0], CSWETBYPASSN);
 or (CSWEMTBYPASS[1], Mint[1], CSWETBYPASSN);
 or (CSWEMTBYPASS[2], Mint[2], CSWETBYPASSN);
 or (CSWEMTBYPASS[3], Mint[3], CSWETBYPASSN);
 or (CSWEMTBYPASS[4], Mint[4], CSWETBYPASSN);
 or (CSWEMTBYPASS[5], Mint[5], CSWETBYPASSN);
 or (CSWEMTBYPASS[6], Mint[6], CSWETBYPASSN);
 or (CSWEMTBYPASS[7], Mint[7], CSWETBYPASSN);

    specify
    specparam


         tckl_tck_ry = 0.00,
         tcycle_taa_ry = 0.00,

         
         
	 tms = 0.0,
         tmh = 0.0,
         tcycle = 0.0,
         tckh = 0.0,
         tckl = 0.0,
         ttms = 0.0,
         ttmh = 0.0,
         tps = 0.0,
         tph = 0.0,
         tws = 0.0,
         twh = 0.0,
         tas = 0.0,
         tah = 0.0,
         tds = 0.0,
         tdh = 0.0;
        /*---------------------- Timing Checks ---------------------*/

	$setup(posedge A[0], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[1], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[2], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[3], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[4], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[5], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[6], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[7], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[8], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(posedge A[9], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[0], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[1], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[2], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[3], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[4], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[5], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[6], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[7], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[8], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$setup(negedge A[9], posedge CK &&& (CSNint != 1), tas, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[0], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[1], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[2], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[3], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[4], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[5], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[6], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[7], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[8], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), posedge A[9], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[0], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[1], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[2], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[3], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[4], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[5], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[6], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[7], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[8], tah, TimingViol_addr);
	$hold(posedge CK &&& (CSNint != 1), negedge A[9], tah, TimingViol_addr);
	$setup(posedge D[0], posedge CK &&& (CSWEMTBYPASS[0] != 1), tds, TimingViol_data_0);
	$setup(posedge D[1], posedge CK &&& (CSWEMTBYPASS[1] != 1), tds, TimingViol_data_1);
	$setup(posedge D[2], posedge CK &&& (CSWEMTBYPASS[2] != 1), tds, TimingViol_data_2);
	$setup(posedge D[3], posedge CK &&& (CSWEMTBYPASS[3] != 1), tds, TimingViol_data_3);
	$setup(posedge D[4], posedge CK &&& (CSWEMTBYPASS[4] != 1), tds, TimingViol_data_4);
	$setup(posedge D[5], posedge CK &&& (CSWEMTBYPASS[5] != 1), tds, TimingViol_data_5);
	$setup(posedge D[6], posedge CK &&& (CSWEMTBYPASS[6] != 1), tds, TimingViol_data_6);
	$setup(posedge D[7], posedge CK &&& (CSWEMTBYPASS[7] != 1), tds, TimingViol_data_7);
	$setup(negedge D[0], posedge CK &&& (CSWEMTBYPASS[0] != 1), tds, TimingViol_data_0);
	$setup(negedge D[1], posedge CK &&& (CSWEMTBYPASS[1] != 1), tds, TimingViol_data_1);
	$setup(negedge D[2], posedge CK &&& (CSWEMTBYPASS[2] != 1), tds, TimingViol_data_2);
	$setup(negedge D[3], posedge CK &&& (CSWEMTBYPASS[3] != 1), tds, TimingViol_data_3);
	$setup(negedge D[4], posedge CK &&& (CSWEMTBYPASS[4] != 1), tds, TimingViol_data_4);
	$setup(negedge D[5], posedge CK &&& (CSWEMTBYPASS[5] != 1), tds, TimingViol_data_5);
	$setup(negedge D[6], posedge CK &&& (CSWEMTBYPASS[6] != 1), tds, TimingViol_data_6);
	$setup(negedge D[7], posedge CK &&& (CSWEMTBYPASS[7] != 1), tds, TimingViol_data_7);
	$hold(posedge CK &&& (CSWEMTBYPASS[0] != 1), posedge D[0], tdh, TimingViol_data_0);
	$hold(posedge CK &&& (CSWEMTBYPASS[1] != 1), posedge D[1], tdh, TimingViol_data_1);
	$hold(posedge CK &&& (CSWEMTBYPASS[2] != 1), posedge D[2], tdh, TimingViol_data_2);
	$hold(posedge CK &&& (CSWEMTBYPASS[3] != 1), posedge D[3], tdh, TimingViol_data_3);
	$hold(posedge CK &&& (CSWEMTBYPASS[4] != 1), posedge D[4], tdh, TimingViol_data_4);
	$hold(posedge CK &&& (CSWEMTBYPASS[5] != 1), posedge D[5], tdh, TimingViol_data_5);
	$hold(posedge CK &&& (CSWEMTBYPASS[6] != 1), posedge D[6], tdh, TimingViol_data_6);
	$hold(posedge CK &&& (CSWEMTBYPASS[7] != 1), posedge D[7], tdh, TimingViol_data_7);
	$hold(posedge CK &&& (CSWEMTBYPASS[0] != 1), negedge D[0], tdh, TimingViol_data_0);
	$hold(posedge CK &&& (CSWEMTBYPASS[1] != 1), negedge D[1], tdh, TimingViol_data_1);
	$hold(posedge CK &&& (CSWEMTBYPASS[2] != 1), negedge D[2], tdh, TimingViol_data_2);
	$hold(posedge CK &&& (CSWEMTBYPASS[3] != 1), negedge D[3], tdh, TimingViol_data_3);
	$hold(posedge CK &&& (CSWEMTBYPASS[4] != 1), negedge D[4], tdh, TimingViol_data_4);
	$hold(posedge CK &&& (CSWEMTBYPASS[5] != 1), negedge D[5], tdh, TimingViol_data_5);
	$hold(posedge CK &&& (CSWEMTBYPASS[6] != 1), negedge D[6], tdh, TimingViol_data_6);
	$hold(posedge CK &&& (CSWEMTBYPASS[7] != 1), negedge D[7], tdh, TimingViol_data_7);

	
        $setup(posedge CSN, edge[01,0x,x1,1x] CK &&& (TBYPASSint != 1), tps, TimingViol_csn);
	$setup(negedge CSN, edge[01,0x,x1,1x] CK &&& (TBYPASSint != 1), tps, TimingViol_csn);
	$hold(edge[01,0x,x1,x0] CK &&& (TBYPASSint != 1), posedge CSN, tph, TimingViol_csn);
	$hold(edge[01,0x,x1,x0] CK &&& (TBYPASSint != 1), negedge CSN, tph, TimingViol_csn);
        $setup(posedge WEN, edge[01,0x,x1,1x] CK &&& (CSNint != 1), tws, TimingViol_wen);
        $setup(negedge WEN, edge[01,0x,x1,1x] CK &&& (CSNint != 1), tws, TimingViol_wen);
        $hold(edge[01,0x,x1,x0] CK &&& (CSNint != 1), posedge WEN, twh, TimingViol_wen);
        $hold(edge[01,0x,x1,x0] CK &&& (CSNint != 1), negedge WEN, twh, TimingViol_wen);
        $period(posedge CK &&& (CSNint != 1), tcycle, TimingViol_tcycle);
        $width(posedge CK &&& (CSNint != 1'b1), tckh, 0, TimingViol_tckh);
        $width(negedge CK &&& (CSNint != 1'b1), tckl, 0, TimingViol_tckl);
        $setup(posedge TBYPASS, posedge CK &&& (CS != 1),ttms, TimingViol_tbypass);
        $setup(negedge TBYPASS, posedge CK &&& (CS != 1),ttms, TimingViol_tbypass);
        $hold(posedge CK &&& (CS != 1), posedge TBYPASS, ttmh, TimingViol_tbypass); 
        $hold(posedge CK &&& (CS != 1), negedge TBYPASS, ttmh, TimingViol_tbypass); 




	endspecify

always @(CKint)
begin
   CKreg <= CKint;
end

//latch input signals
always @(posedge CKint)
begin
   if (CSNint !== 1)
   begin
      Dreg = Dint;
      Mreg = Mint;
      WENreg = WENint;
      Areg = Aint;
   end
   CSNreg = CSNint;
end
     


// conversion from registers to array elements for data setup violation notifiers

always @(TimingViol_data_0)
begin
   TimingViol_data[0] = TimingViol_data_0;
end


always @(TimingViol_data_1)
begin
   TimingViol_data[1] = TimingViol_data_1;
end


always @(TimingViol_data_2)
begin
   TimingViol_data[2] = TimingViol_data_2;
end


always @(TimingViol_data_3)
begin
   TimingViol_data[3] = TimingViol_data_3;
end


always @(TimingViol_data_4)
begin
   TimingViol_data[4] = TimingViol_data_4;
end


always @(TimingViol_data_5)
begin
   TimingViol_data[5] = TimingViol_data_5;
end


always @(TimingViol_data_6)
begin
   TimingViol_data[6] = TimingViol_data_6;
end


always @(TimingViol_data_7)
begin
   TimingViol_data[7] = TimingViol_data_7;
end




ST_SPHS_1024x8m8_L_main ST_SPHS_1024x8m8_L_maininst (Q_glitchint,  Q_dataint, Q_gCKint , RY_rfCKint, RY_rrCKint, RY_frCKint, ICRYint, delTBYPASSint, TBYPASS_D_Qint, TBYPASS_mainint, CKint,  CSNint , TBYPASSint, WENint,  Aint, Dint, Mint, debug_level  , TimingViol_addr, TimingViol_data, TimingViol_csn, TimingViol_wen, TimingViol_tckh, TimingViol_tckl, TimingViol_tcycle, TimingViol_tbypass, TimingViol_mask    );


ST_SPHS_1024x8m8_L_OPschlr ST_SPHS_1024x8m8_L_OPschlrinst (Qint, RYint,  Q_gCKint, Q_glitchint,  Q_dataint, RY_rfCKint, RY_rrCKint, RY_frCKint, ICRYint, delTBYPASSint, TBYPASS_D_Qint, TBYPASS_mainint);

defparam ST_SPHS_1024x8m8_L_maininst.Fault_file_name = Fault_file_name;
defparam ST_SPHS_1024x8m8_L_maininst.ConfigFault = ConfigFault;
defparam ST_SPHS_1024x8m8_L_maininst.max_faults = max_faults;
defparam ST_SPHS_1024x8m8_L_maininst.MEM_INITIALIZE = MEM_INITIALIZE;
defparam ST_SPHS_1024x8m8_L_maininst.BinaryInit = BinaryInit;
defparam ST_SPHS_1024x8m8_L_maininst.InitFileName = InitFileName;

endmodule
`endif

`delay_mode_path
`endcelldefine
`disable_portfaults
`nosuppress_faults




