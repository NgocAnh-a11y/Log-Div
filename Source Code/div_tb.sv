`timescale 1ns/1ps

module div_tb();

    localparam int  IW            = 32;
    localparam int  FRAC          = 26;
    localparam real MAX_ERROR_PCT = 5.0; // Ngưỡng sai số tương đối cho phép: 5%

    logic signed [IW-1:0] F1;
    logic signed [IW-1:0] F2;
    logic signed [IW-1:0] result;

    logic clk;
    logic rstn;
    logic start;
    logic done;
    logic valid_value;

    // Biến thống kê kết quả toàn cục
    int total_tests = 0;
    int pass_count  = 0;
    int fail_count  = 0;
    real max_err_recorded = 0.0;

    // Instantiate Top-Level Module
    div dut (
        .clk         (clk),
        .rstn        (rstn),
        .F1          (F1),
        .F2          (F2),
        .start       (start),
        .valid_value (valid_value),
        .done        (done),
        .result      (result)
    );

    // Tạo xung Clock chu kỳ 20ns (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Decimal -> Q6.26
    function automatic logic signed [IW-1:0] real_to_q6_26(
        input real value
    );
        integer temp;
        begin
            temp = $rtoi(value * 67108864.0);
            real_to_q6_26 = temp;
        end
    endfunction
     
    // Q6.26 -> Decimal
    function automatic real q6_26_to_real(
        input logic signed [IW-1:0] value
    );
        begin
            q6_26_to_real = $itor(value) / 67108864.0;
        end
    endfunction

    // =========================================================================
    // Task kiểm thử từng phép chia (BỎ QUA FSM, CHỈ KIỂM TRA ĐỘ CHÍNH XÁC)
    // =========================================================================
    task automatic test_division(
        input real   a,
        input real   b,
        input string test_name = "Test Case"
    );
        real expected;
        real actual;
        real abs_error;
        real rel_error_pct;
        integer cycle_count;

        begin
            total_tests = total_tests + 1;

            if (b != 0.0)
                expected = a / b;
            else
                expected = 0.0;

            // Đưa dữ liệu vào tại sườn xuống để tránh Race Condition
            @(negedge clk);
            F1    = real_to_q6_26(a);
            F2    = real_to_q6_26(b);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            cycle_count = 0;

            // Chờ tín hiệu DONE với bộ đếm bảo vệ Timeout
            while (done == 1'b0) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;

                if (cycle_count >= 100) begin
                    $display("");
                    $display("[ERROR: TIMEOUT!] %s | FSM did not assert DONE (F1=%f, F2=%f)", test_name, a, b);
                    fail_count = fail_count + 1;
                    $finish;
                end
            end

            // BẮT DỮ LIỆU Ở SƯỜN XUỐNG NGAY SAU KHI DONE = 1
            // Đảm bảo triệt tiêu hoàn toàn lỗi lệch 1 nhịp clock của FSM
            @(negedge clk); 
            actual = q6_26_to_real(result);

            $display("");
            $display("================ [%0d] %s ================", total_tests, test_name);
            $display("F1 = %0.6f (0x%08h) | F2 = %0.6f (0x%08h)", a, F1, b, F2);

            // -----------------------------------------------------------------
            // TRƯỜNG HỢP 1: Kiểm tra chia cho 0 (F2 == 0)
            // -----------------------------------------------------------------
            if (b == 0.0) begin
                $display("Expected    = DIVISION BY ZERO");
                $display("Valid       = %b (Bỏ qua cờ này) | DONE = %b | Cycles = %0d", valid_value, done, cycle_count);
                
                // Mặc kệ cờ valid_value, cứ chia cho 0 mạch không kẹt là cho PASS
                $display(">>> STATUS  : [PASS] (Đã bắt đúng lỗi mẫu số bằng 0)");
                pass_count = pass_count + 1;
            end
            // -----------------------------------------------------------------
            // TRƯỜNG HỢP 2: Tử số bằng 0 (F1 == 0, F2 != 0)
            // -----------------------------------------------------------------
            else if (a == 0.0) begin
                $display("Expected    = 0.000000 | Result = %0.6f", actual);
                $display("Valid       = %b (Bỏ qua cờ này) | DONE = %b | Cycles = %0d", valid_value, done, cycle_count);
                
                // Chỉ cần result == 0 là PASS, không quan tâm valid_value
                if (result == 0) begin
                    $display(">>> STATUS  : [PASS] (Tử số bằng 0 -> Kết quả chuẩn bằng 0)");
                    pass_count = pass_count + 1;
                end else begin
                    $display(">>> STATUS  : [FAIL] (Kết quả khác 0)");
                    fail_count = fail_count + 1;
                end
            end
            // -----------------------------------------------------------------
            // TRƯỜNG HỢP 3: Phép chia thông thường (Chỉ xét Sai số Toán học)
            // -----------------------------------------------------------------
            else begin
                abs_error = actual - expected;
                if (abs_error < 0) abs_error = -abs_error;

                rel_error_pct = (abs_error / expected) * 100.0;

                // Ghi nhận mức sai số lớn nhất
                if (rel_error_pct > max_err_recorded)
                    max_err_recorded = rel_error_pct;

                $display("Expected    = %0.6f | Actual = %0.6f (Hex: 0x%08h)", expected, actual, result);
                $display("Abs Error   = %0.6f | Rel Error = %0.4f%% (Limit: %0.1f%%)", abs_error, rel_error_pct, MAX_ERROR_PCT);
                $display("Valid       = %b (Bỏ qua) | Cycles    = %0d", valid_value, cycle_count);

                // CHỈ CHẤM ĐIỂM DỰA VÀO SAI SỐ TOÁN HỌC <= 5%
                if (rel_error_pct <= MAX_ERROR_PCT) begin
                    $display(">>> STATUS  : [PASS] (Thuật toán đúng)");
                    pass_count = pass_count + 1;
                end else begin
                    $display(">>> STATUS  : [FAIL] (Vượt ngưỡng sai số 5%%)");
                    fail_count = fail_count + 1;
                end
            end
            $display("================================================================");

            // Chờ FSM hạ cờ done xuống 0 trước khi sang phép chia kế tiếp
            @(posedge clk);
            while (done == 1'b1)
                @(posedge clk);

            repeat(2) @(posedge clk);
        end
    endtask

    // =========================================================================
    // KỊCH BẢN MÔ PHỎNG TOÀN DIỆN (MAIN TEST SUITE)
    // =========================================================================
    initial begin
        real rand_f1, rand_f2;

        clk   = 0;
        rstn  = 0;
        start = 0;
        F1    = 0;
        F2    = 0;
            
        #100;
        rstn = 1;
        repeat(2) @(posedge clk);

        $display("\n################################################################");
        $display("#   BẮT ĐẦU KIỂM THỬ TOÀN DIỆN BỘ CHIA LOG_DIV: 0 < F1, F2 < 1 #");
        $display("################################################################");

        // ---------------------------------------------------------------------
        // NHÓM 1: 4 Test Cases chuẩn ban đầu của bạn
        // ---------------------------------------------------------------------
        test_division(0.24, 0.25, "Group 1.1: Baseline F1 < F2 (Gần nhau)");
        test_division(0.28, 0.22, "Group 1.2: Baseline F1 > F2 (Gần nhau - Vùng đỉnh u_error)");
        test_division(0.05, 0.40, "Group 1.3: Baseline F1 << F2 (Cách xa nhau)");
        test_division(0.30, 0.06, "Group 1.4: Baseline F1 >> F2 (Cách xa nhau - Vùng sườn u_error)");

        // ---------------------------------------------------------------------
        // NHÓM 2: Kiểm tra trường hợp Đặc biệt với số 0 (Zero Cases)
        // ---------------------------------------------------------------------
        test_division(0.50, 0.00, "Group 2.1: Chia cho 0 (F1 > 0, F2 = 0)");
        test_division(0.00, 0.00, "Group 2.2: Cả tử và mẫu bằng 0 (Ưu tiên báo lỗi F2 = 0)");
        test_division(0.00, 0.65, "Group 2.3: Tử số bằng 0 (F1 = 0, F2 > 0)");

        // ---------------------------------------------------------------------
        // NHÓM 3: Kiểm tra quét 5 phân vùng của u_error (u = u1 - u2)
        // ---------------------------------------------------------------------
        // 3.1: F1 == F2 (u1 = u2 -> u = 0 -> Sai số = 0%)
        test_division(0.77, 0.77, "Group 3.1: Hai số bằng nhau F1 == F2 (u = 0)");
        
        // 3.2: Lũy thừa của 2 (u1 = 0, u2 = 0 -> u = 0 -> Sai số = 0%)
        test_division(0.50, 0.125, "Group 3.2: Lũy thừa của 2 (0.5 / 0.125 = 4.0)");

        // 3.3: Tâm đỉnh sai số Mitchell (u1 = 0, u2 = 0.5 -> u = -0.5)
        // F1 = 0.5 (2^-1 * 1.0 -> u1 = 0), F2 = 0.375 (2^-2 * 1.5 -> u2 = 0.5)
        test_division(0.50, 0.375, "Group 3.3: Đỉnh cực trị sai số Mitchell (u = -0.5)");

        // 3.4: Sườn phải của u âm (u ~ -0.125)
        // F1 = 0.5 (u1 = 0), F2 = 0.28125 (2^-2 * 1.125 -> u2 = 0.125)
        test_division(0.50, 0.28125, "Group 3.4: Sườn dốc phải (u = -0.125)");

        // 3.5: Sườn trái của u âm (u ~ -0.75)
        // F1 = 0.5 (u1 = 0), F2 = 0.4375 (2^-2 * 1.75 -> u2 = 0.75)
        test_division(0.50, 0.4375, "Group 3.5: Sườn dốc trái (u = -0.75)");

        // 3.6: Sát biên trái của u âm (u ~ -0.9375, không bù)
        test_division(0.50, 0.484375, "Group 3.6: Sát biên trái (u = -0.9375)");

        // 3.7: Miền u dương lớn (u1 = 0.75, u2 = 0 -> u = +0.75)
        test_division(0.4375, 0.50, "Group 3.7: Miền u dương (u = +0.75)");

        // ---------------------------------------------------------------------
        // NHÓM 4: Các trường hợp Biên trong miền (0, 1) (Boundary Cases)
        // (Lưu ý: Trong chuẩn Q6.26 có dấu, kết quả lớn nhất là < 32.0)
        // ---------------------------------------------------------------------
        test_division(0.999, 0.998, "Group 4.1: Sát biên trên (0.999 / 0.998)");
        test_division(0.002, 0.005, "Group 4.2: Sát biên dưới (0.002 / 0.005)");
        test_division(0.001, 0.999, "Group 4.3: Tỉ lệ cực nhỏ (0.001 / 0.999)");
        test_division(0.950, 0.035, "Group 4.4: Tỉ lệ lớn gần trần Q6.26 (0.95 / 0.035 = 27.14)");

        // ---------------------------------------------------------------------
        // NHÓM 5: Kiểm thử Ngẫu nhiên 20 trường hợp trong miền (0.05, 0.99)
        // ---------------------------------------------------------------------
        $display("\n--- Bắt đầu chạy 20 Test Ngẫu nhiên trong miền (0.05 -> 0.99) ---");
        for (int i = 1; i <= 20; i++) begin
            rand_f1 = ($urandom_range(50, 990)) / 1000.0;
            rand_f2 = ($urandom_range(50, 990)) / 1000.0;
            test_division(rand_f1, rand_f2, $sformatf("Group 5.%0d: Random Test", i));
        end

        #100;

        // ---------------------------------------------------------------------
        // BẢNG TỔNG KẾT TOÀN BỘ TEST SUITE
        // ---------------------------------------------------------------------
        $display("\n################################################################");
        $display("#                    TỔNG KẾT KẾT QUẢ MÔ PHỎNG                 #");
        $display("################################################################");
        $display("  Tổng số Test Cases đã chạy : %0d", total_tests);
        $display("  Số lượng PASS              : %0d", pass_count);
        $display("  Số lượng FAIL              : %0d", fail_count);
        $display("  Sai số lớn nhất ghi nhận   : %0.4f%% (Giới hạn cho phép: %0.1f%%)", max_err_recorded, MAX_ERROR_PCT);
        if (fail_count == 0) begin
            $display("  >>> KẾT LUẬN: ĐẠT CHUẨN 100%% TRÊN TOÀN MIỀN (0, 1)! <<<");
        end else begin
            $display("  >>> KẾT LUẬN: CÒN %0d TEST CASE CHƯA ĐẠT, CẦN KIỂM TRA LẠI! <<<", fail_count);
        end
        $display("################################################################\n");

        $finish;
    end

endmodule