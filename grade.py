import csv
import os
amount = 96
with open("multdiv_grade.csv", "r") as nameFile:
    with open("Students/multdiv_grades.csv", "w") as grades:
        writer = csv.writer(grades)
        writer.writerow(["Name", "Behavioral", "", "Timing", ""])
        for person in csv.reader(nameFile):
            toWrite = [person[0]]
            first = person[0].split(" ")[0]
            print("Testing: %s\n" % first)
            os.system("git clone %s Students/%s" % (person[1], first))
            os.system("mkdir Students/%s/results" % first)
            print("\n")
            for i in range(2):
                mode = "timing" if i else "behavioral"
                exitCode = os.system("/tools/Xilinx/Vivado/2020.1/bin/vivado -mode batch -notrace -source build.tcl -nojournal -nolog -tclargs multdiv Students/%s %d 2> Students/%s/results/%s_error.txt > Students/%s/results/%s_results.txt" % (first, i, first, mode, first, mode))
                
                if not exitCode:
                    with open("tests/multdiv/multdiv_diff.csv", "r") as diff:
                        n = -1
                        for stuff in csv.reader(diff):
                            n = n+1

                    os.system("mv tests/multdiv/multdiv_diff.csv Students/%s/results/multdiv_%s_diff.csv" % (first, mode))
                    os.system("mv tests/multdiv/multdiv_actual.csv Students/%s/results/multdiv_%s_actual.csv" % (first, mode))

                    percent = float(amount - n)/float(amount)
                    amountCorr = amount - n
                    print("%s: Percent Correct: %f, Amount Correct: %d" % (mode, percent, amountCorr))
                    toWrite.append(percent)
                    toWrite.append(amountCorr)
                else:
                    print(mode + " Failed")
                    toWrite.append("Failed")
                    toWrite.append("")

                if i:
                    print("\n")
            writer.writerow(toWrite)

os.system("zip -r Students.zip Students -i '*.csv' '*.vcd' -x *.v")