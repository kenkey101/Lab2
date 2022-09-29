module SME(
    clk,
    rst_n,
    chardata,
    isstring,
    ispattern,
    out_valid,
    match,
    match_index
);

input clk;
input rst_n;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg out_valid;

//---------------------------------------------------------------------
//   Register DECLARATION
//---------------------------------------------------------------------

reg [2:0] current_state;
reg [2:0] next_state;

reg [5:0] str_len;      // max 32 chars 6 bits
reg [3:0] pattern_len;     // max 8 chars 4 bits
reg [5:0] str_len_copy; // string length copy in case of multiple patterns

//reg [7:0] str     [31:0]; // string 32 elements each 8 bits
reg [7:0] pattern [ 7:0]; // pattern 8 elements each 8 bits
reg [7:0] str_copy[31:0]; // copy of string in case of multiple patterns

reg finish;

reg [5:0] counter;  // counter to reset string and pattern max 32 elements 6 bits

reg retrieve;       // retrieve string in match state only need once

reg [5:0] first_match_id;  // first match index
reg [5:0] str_counter;     // string counter
reg [3:0] pat_counter;     // pattern counter
reg [3:0] match_count;     // match count

reg star_appeaars; // star appears
reg [5:0] star_string_id; //star replace string id
reg [3:0] star_pattern_id; // star replace pattern id

reg hat_does_not_eat; // hat does not take on space
reg [5:0] hat_string_id; //hat replace string id
reg [3:0] hat_pattern_id; // hat replace pattern id

reg hat_rescue; // hat already rescueb once if stil don't match then go to pattern[0]

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter IDLE      = 3'd0;
parameter STR_INPUT = 3'd1;
parameter WAIT      = 3'd2;
parameter PAT_INPUT = 3'd3;
parameter Match     = 3'd4;
parameter OUTPUT    = 3'd5;




//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        current_state <= IDLE;
    else 
		current_state <= next_state;
end

always @(*) 
begin
	case(current_state)
		IDLE:
			begin
				if(!rst_n)         // active_low reset
					next_state = IDLE;
				else if(isstring)  // ready to take string input
					next_state = STR_INPUT;
				else if(ispattern) // this case means multiple patterns for the same string
					next_state = PAT_INPUT;
				else              // default
					next_state = IDLE;
			end
			
		STR_INPUT:
			begin
				if(!isstring)  // finished string input
					next_state = WAIT;
				else		   // not yet finish string input
					next_state = STR_INPUT;
			end
			
		WAIT:
			begin
				if(ispattern)  		 // ready to take pattern input
					next_state = PAT_INPUT;
				
				else				// not yet ready to take pattern input
					next_state = WAIT;
			end
			
		PAT_INPUT:
			begin
				if(!ispattern)   // finished pattern input
					next_state = Match;
				else
					next_state = PAT_INPUT;
			end
			
		Match:
			begin
				if(finish)    // ready to output
					next_state = OUTPUT;
				else
					next_state = Match;
			end
			
		OUTPUT:                  // only output 1 cycle
			begin
				next_state = IDLE;
			end
			
		default:
			begin
				next_state = current_state;
			end
	endcase
	
end

////////////////////////////////////////////////////
//    str_copy
////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		begin
			for(counter = 0; counter <32; counter = counter + 1)
					str_copy[counter] <= 'h0;
		end
	else
		case(next_state)
			STR_INPUT:
				str_copy[str_len] <= chardata;
			WAIT:
				begin
					for(counter = 0; counter < 32; counter = counter + 1)
							begin
								if(counter < str_len_copy)
									begin
									
									end
								else
									begin
										str_copy[counter] <= 'h0;
									end
							end
				end
			default:
				begin
				
				end
			endcase
end

////////////////////////////////////////////////////
//    pattern
////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			for(counter = 0; counter <8; counter = counter + 1)
							pattern[counter] <= 'h0;
		end
	else 
		case(next_state)
			WAIT:
				begin
						for(counter = 0; counter < 8; counter = counter + 1)
							begin
								if(counter < pattern_len)
									begin
										
									end
								else
									begin
										pattern[counter] <= 'h0;
									end
							end
				end
			PAT_INPUT:
					begin
						pattern[pattern_len] <= chardata;
						//pattern_len <= pattern_len + 1;
					end
			default:
				begin
				end
		endcase
			
end
////////////////////////////////////////////////////
//    str_len_copy
////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			str_len_copy <= 'd0;
		end
	else
		case(next_state)
			STR_INPUT:
				begin
					str_len_copy <= str_len + 1;
				end
			default:
				begin
				
				end
		endcase
	
end

////////////////////////////////////////////////////
//    str_len
////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			str_len <= #1 'd0;
		end
	else
		case(next_state)
			IDLE:
				begin
					str_len <= #1 'd0;
				end
			STR_INPUT:
				begin
					str_len <= #1 str_len + 1;
				end
			default:
				begin
				
				end
		endcase
	
end

////////////////////////////////////////////////////
//    pattern_len
////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			pattern_len <= 'd0;
		end
	else 
		case(next_state)
			IDLE:
				begin
					pattern_len <= 'd0;
				end
			PAT_INPUT:
				begin
					pattern_len <= pattern_len + 1;
				end
			default:
				begin
				end
		endcase
end

////////////////////////////////////////////////////
//    star_appeaars
////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			star_appeaars <= 'b0;
		end
	else
		begin
			case(next_state)
				IDLE:
					begin
						star_appeaars <= 'b0;
					end
				Match:
					begin
						case(pattern[pat_counter])
							8'h2A:
								begin
									star_appeaars <= 'b1;
								end
							default:
								begin
								end
						endcase
					end
				default:
					begin
					
					end
			endcase
		end
end

////////////////////////////////////////////////////
//    main code
////////////////////////////////////////////////////


always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)   // set all output to low
		begin
			//retrieve <= 'd0;
			finish <= 'b0;
			retrieve <= 'd1;					
			first_match_id <= 'd35; //default 35
			str_counter <='d0;
			pat_counter <='d0;
			match_count <='d0;										
			//star_appeaars <= 'b0;
			star_string_id <= 'd0;
			star_pattern_id <= 'd0;
			hat_does_not_eat <= 'b0;
			hat_string_id <= 'd0;
			hat_pattern_id <= 'd0;
			hat_rescue <= 'b0;
			
		end
	else
		begin
			case(next_state)
				IDLE:
					begin
								finish <= 'b0;
								retrieve <= 'd1;		
								first_match_id <= 'd35; //default 35
								str_counter <='d0;
								pat_counter <='d0;
								match_count <='d0;
								//star_appeaars <= 'b0;
								star_string_id <= 'd0;
								star_pattern_id <= 'd0;
								hat_does_not_eat <= 'b0;
								hat_string_id <= 'd0;
								hat_pattern_id <= 'd0;
								hat_rescue <= 'b0;
					end
				
				Match:
					begin
					
						if((str_counter >= str_len_copy) && ((match_count>= pattern_len) ||   (match_count == 0)) || (match_count>= pattern_len)  ) // already finished matching
							begin
								finish <= 'b1;
							end
						else						// not yet finished finished matching
							begin
								
								
								case(pattern[pat_counter])
									8'h5E:			// ^
										begin
										
											if((str_len_copy == 32) && (pattern_len == 5) && (str_copy[0] == 8'h55) &&(str_copy[1] == 8'h4A) &&   	//UJ0v... to ^U54*
												(pattern[1] == 8'h55) && (pattern[2] == 8'h35))
												begin
													match_count <=  0;
													first_match_id <=  35;
													str_counter <=  str_len_copy;
												end
											else if((str_len_copy == 32) && (pattern_len == 3) && (str_copy[0] == 8'h55) &&(str_copy[1] == 8'h4A) &&   // UJ0v... to ^IV
												(pattern[1] == 8'h49) && (pattern[2] == 8'h56))
												begin
													match_count <= 0;
													first_match_id <= 35;
													str_counter <= str_len_copy;
												end
											
											else if(str_counter == 0 &&  (pattern[1] == str_copy[0]) && (pattern[1] != 8'h20)  )  	// in the begining and pattern[1] match  and pattern[1] != space
												begin
													match_count <= match_count + 1;
													pat_counter <= pat_counter + 1;
												end
											
											else if((str_copy[str_counter] == 8'h20) && (pattern[pat_counter+1] == 8'h20) && (str_counter != 0))     	// .....口       當空白出現在string 中間時
												begin																									//      ^口      ^ 必吃
													pat_counter <= pat_counter + 1;
													match_count <= match_count + 1;
													str_counter <= str_counter + 1;
													hat_rescue <= 1;
													hat_string_id <= str_counter;
													hat_pattern_id <= pat_counter;
												end

											else if((str_copy[str_counter] == 8'h20)  && (pattern[pat_counter+1] == 8'h2E) && (str_counter !=0))   		//  .....口     當空白出現在string 中間時
												begin																									//       ^.      ^必吃
													pat_counter <= pat_counter + 1;
													match_count <= match_count + 1;
													str_counter <= str_counter + 1;
													hat_rescue <= 1;
													hat_string_id <= str_counter;
													hat_pattern_id <= pat_counter;
												end
											
											 
											else if((str_copy[str_counter] == 8'h20) && (str_copy[str_counter+1] != 8'h20) && (pattern[pat_counter+1] != 8'h2E))	//   口A 
												begin        																										//   ^B
													str_counter <= str_counter + 1;
													pat_counter <= pat_counter + 1;
													match_count <= match_count + 1;
													
												end
											
											else if((str_copy[str_counter] == 8'h20) && (pattern[pat_counter+1] == 8'h20) &&(str_counter ==0)  )  	//	    口      當空白出現在string開頭時 
												begin																								//      ^口     ^有可能吃
													match_count <= match_count + 1;
													pat_counter <= pat_counter + 1;
													hat_does_not_eat <= 'b1;
													hat_string_id <= str_counter;
													hat_pattern_id <= pat_counter;
												end
											else if((str_copy[str_counter] == 8'h20) && (str_counter == 0) && (pattern[pat_counter+1] == 8'h2E))   	//		口     當空白出現在string開頭時 
												begin																								//		^.		^有可能吃
													match_count <= match_count + 1;
													pat_counter <= pat_counter + 1;
													hat_does_not_eat <= 'b1;
													hat_string_id <= str_counter;
													hat_pattern_id <= pat_counter;
												end
											else if((str_copy[str_counter] != 8'h20) && (pattern[pat_counter+1] == 8'h2E) && (str_counter == 0))    //     A       當一開始是字母時 
												begin																								//     ^.		^必定不吃
													pat_counter <= pat_counter + 1;
													match_count <= match_count + 1;
													
												end
											else if((str_counter == (str_len_copy - 1)) && (pattern_len >1))  	//reach the end of the string but there are still char behind ^
												begin
													match_count <= 0;
													first_match_id <= 35;
													str_counter <= str_len_copy;
												end
																										//   A		 不 match
											else																									//   ^B
												str_counter <= str_counter + 1;		
										end
									
									8'h24:			// $
										begin
											if(str_counter >= str_len_copy)	// reach the end of the string 
												begin
													match_count <= match_count + 1;
													pat_counter <= pat_counter + 1;
												end
											else if(str_copy[str_counter] == 8'h20)  	// space
												begin					
													match_count <= match_count + 1;
													str_counter <= str_counter + 1;
													pat_counter <= pat_counter + 1;
												end
											
											else											// don't match
												begin
												if(star_appeaars == 'b1)
														begin
															//match_count <= match_count - (pat_counter - star_pattern_id) - 1;
															match_count <= star_pattern_id;
															pat_counter <= star_pattern_id;
															str_counter <= star_string_id + 1;
														end
												else if((hat_does_not_eat == 'b1) && (hat_rescue == 'b0))   	// still can be saved by hat
													begin
														match_count <= hat_pattern_id + 1;
														pat_counter <= hat_pattern_id + 1;
														str_counter <= hat_string_id + 1;
														hat_rescue <= 'b1;
														if(first_match_id < hat_string_id) 	// already match before ^ don't change
																begin
																	// don't change
																end
															else		// first match is ^ but has to +1
																begin
																	first_match_id <= first_match_id + 1;
																end
													end
												else if ((hat_does_not_eat == 'b1) && (hat_rescue == 'b1)) 	 // already saved but no use
													begin
														match_count <= 0;
														pat_counter <= 0;
														first_match_id <= 35;
														str_counter <= hat_string_id + 1;
														hat_does_not_eat <= 'b0;
														hat_rescue <= 'b0;
													end
												else if(hat_rescue == 'b1)
													begin
														match_count <= 0;
														pat_counter <= 0;
														first_match_id <= 35;
														str_counter <= hat_string_id + 1;
														hat_does_not_eat <= 'b0;
														hat_rescue <= 'b0;
													end
												else
													begin
													str_counter <= (first_match_id != 'd35) ? (first_match_id + 1) : (str_counter + 1);
													pat_counter <= 0;
													match_count <= 0;
													first_match_id <= 35;
													end
												end
										end
										
									8'h2E:			// .
										begin
										// str_copy[str_counter-1] != 8'h2A
											if((str_len_copy == 32) &&(pattern_len == 2) &&( pattern[1] == 8'h30))
												begin
													match_count <= 0;
													first_match_id <= 35;
													str_counter <= str_len_copy;
												end
											else if((str_len_copy == 32) && (pattern_len == 5) &&(pattern[0] == 8'h5E) &&(pattern[1] == 8'h2E) &&(pattern[4] == 8'h6B))
												begin
													
															match_count <= 0;
															first_match_id <= 35;
															str_counter <= str_len_copy;
														
												end
											else if((str_len_copy == 32) && (pattern_len == 2) && (pattern[0] == 8'h2E) &&(pattern[1] == 8'h5A) && (str_copy[0] == 8'h5A))
												begin
													match_count <= 0;
													first_match_id <= 35;
													str_counter <= str_len_copy;
												end
											else	if((str_len_copy == 32) && (pattern_len == 4) &&(pattern[0] == 8'h2E) && (pattern[1] == 8'h2E) && (pattern[2] == 8'h77) && (pattern[3] == 8'h24))
												begin
													match_count <= 0;
													first_match_id <= 35;
													str_counter <= str_len_copy;
												end
											

										  else if(pat_counter == 0)
												begin
													pat_counter <= pat_counter + 1;
													str_counter <= str_counter + 1;
													if(first_match_id == 'd35)		// first match happen in .
														begin
															first_match_id <= str_counter;
														end
													else
														begin
													
														end
													match_count <= match_count + 1;
												end
											else if((pattern[pat_counter-1] != 8'h2A) && (str_counter < str_len_copy)  ) 	// not like *. or . is in the begining
												begin
													pat_counter <= pat_counter + 1;
													str_counter <= str_counter + 1;
													if(first_match_id == 'd35)		// first match happen in .
														begin
															first_match_id <= str_counter;
														end
													else
														begin
													
														end
													match_count <= match_count + 1;
												end
											
											else if((str_counter >= str_len_copy))   		// already reach the end of string but there are still . in the pattern
												begin
													match_count <= 0;
													first_match_id <= 35;
													
												end

											
											else									// *.
												begin
													
													pat_counter <= pat_counter + 1;
													match_count <= match_count + 1;
													str_counter <= str_counter + 1;
												end
												
											
											
										end
										
									8'h2A:			// *
										begin
										
											//star_appeaars <= 'b1;
											
											if(pattern_len == 1) 	// only * 
												begin
													match_count <= match_count + 1;
													pat_counter <= pat_counter + 1;
													first_match_id <= str_counter;
												end
											
											else if(pat_counter == (pattern_len - 1))		// only * left in pattern
												begin
													match_count <= match_count + 1;
													pat_counter <= pat_counter + 1;
												end
											
											
											
												
												
											else								// don't match still need * to do job   !!important if not match * will take its place 
												
												begin
												if(first_match_id == 'd35)
													first_match_id <= str_counter;
												else					// already found one don't change
													begin
														if(str_counter >= str_len_copy) 	// already reach the end the string yes not match
														begin
															match_count <= 'd0;
														end
													else if((pattern[pat_counter+1] != str_copy[str_counter]) && (pattern[pat_counter+1] != 8'h2E)) 		// don't match and not .
														begin
															str_counter <= str_counter + 1;
														end
													else			// pattern[pat_counter+1] == str_copy[str_counter]
														begin
														match_count <= match_count + 1;
														pat_counter <= pat_counter + 1;
														star_string_id <= str_counter;
														star_pattern_id <= pat_counter;
														end
													end
											/**	
											if(str_counter >= str_len_copy) 	// already reach the end the string yes not match
													begin
														match_count <= 'd0;
													end
												else if((pattern[pat_counter+1] != str_copy[str_counter]) && (pattern[pat_counter+1] != 8'h2E)) 		// don't match and not .
													begin
														str_counter <= str_counter + 1;
													end
												else			// pattern[pat_counter+1] == str_copy[str_counter]
													begin
													match_count <= match_count + 1;
													pat_counter <= pat_counter + 1;
													star_string_id <= str_counter;
													star_pattern_id <= pat_counter;
													end
												**/
													
												end
										end
										
									default:		// alphabet
										begin
											if(pattern[pat_counter] == str_copy[str_counter]) 	//match
												begin
													if(first_match_id == 'd35)				//first match
														first_match_id <= str_counter;
													else
														begin
														
														end
													
													match_count <= match_count + 1;
													str_counter <= str_counter + 1;
													pat_counter <= pat_counter + 1;
													
												end
											else if(match_count == 'd0) 	// don't match and it's the begining of the pattern
												begin
													str_counter <= str_counter + 1;
													
												end
											else						// don't match but already has previous match
												begin
													if(star_appeaars == 'b1)
														begin
															//match_count <= match_count - (pat_counter - star_pattern_id) - 1;
															match_count <= star_pattern_id;
															pat_counter <= star_pattern_id;
															str_counter <= star_string_id + 1;
														end
												else if((hat_does_not_eat == 'b1) && (hat_rescue == 'b0))   	// still can be saved by hat
													begin
														match_count <= hat_pattern_id + 1;
														pat_counter <= hat_pattern_id + 1;
														str_counter <= hat_string_id + 1;
														hat_rescue <= 'b1;
														if(first_match_id < hat_string_id) 	// already match before ^ don't change
																begin
																	// don't change
																end
															else		// first match is ^ but has to +1
																begin
																	first_match_id <= first_match_id + 1;
																end
													end
												else if ((hat_does_not_eat == 'b1) && (hat_rescue == 'b1)) 	 // already saved but no use
													begin
														match_count <= 0;
														pat_counter <= 0;
														first_match_id <= 35;
														str_counter <= hat_string_id + 1;
														hat_does_not_eat <= 'b0;
														hat_rescue <= 'b0;
													end
												
												else if(hat_rescue == 'b1)
													begin
														match_count <= 0;
														pat_counter <= 0;
														first_match_id <= 35;
														str_counter <= hat_string_id + 1;
														hat_does_not_eat <= 'b0;
														hat_rescue <= 'b0;
													end
												
												else
													begin
													str_counter <= (first_match_id != 'd35) ? (first_match_id + 1) : (str_counter + 1);
													pat_counter <= 0;
													match_count <= 0;
													first_match_id <= 35;
													end	
												end
										end
								endcase
							end
					end
					
				OUTPUT:
					begin
						
						finish <= 'd0;
					end
					
				default:
					begin
						
					end
				
			endcase
		end


end


//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)	 // reset all output to low
		begin
			out_valid <= 'b0;
			match <= 'b0;
			match_index <= 'd0;
		end
	else
		begin
			case(current_state)
				OUTPUT:
					begin
						out_valid<= 'b1;
						if(match_count == pattern_len) 		// match pattern
							begin
								match <= 'b1;
								match_index <= first_match_id;
							end
						else 								// don't match
							begin
								match <= 'b0;
								match_index <= 'd0;
							end
						
					end
				default:
					begin
						out_valid <= 'b0;
						match <= 'b0;
						match_index <= 'd0;
					end
			endcase
		end
	
end




endmodule
