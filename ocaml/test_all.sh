#!/bin/bash

get_test_name () {
	local full_path=$1
	test_path="${full_path%.*}" # strip any type
	test_name="${test_path##*/}" # strip preceding path
}

go_tests=$(find tests/go_tests -iname "*.wasp")
echo "PARSING GO_TESTS TESTS"
for file in $go_tests; do
	get_test_name "$file"

	go_file="tests/go_tests/$test_name.go"
	wasp_file="tests/go_tests/$test_name.wasp"
	expected_file="tests/go_tests/$test_name.expected"

	./wasp -g "$wasp_file" > "$go_file"

	TEST=`diff -q $go_file $expected_file | wc -l`

	if [ "$TEST" -eq 0 ]
	then echo "SUCCESS: 	$test_name"
	elif [ "$TEST" -ne 0 ]
	then echo "FAIL:		$test_name"
	fi

	rm "$go_file"
done

compiler_tests=$(find tests/compiler -iname "*.wasp")
echo "PARSING COMPILER TESTS"
for file in $compiler_tests; do
	get_test_name "$file"

	output_file="tests/compiler/$test_name.output"
	wasp_file="tests/compiler/$test_name.wasp"
	expected_file="tests/compiler/$test_name.expected"

	# fail_test set to true when expected to fail
	fail_test=$(echo "$file" | grep "fail_")

	if [ $fail_test ]
		then ./wasp -g "$wasp_file" &> "$output_file"
	else
		 ./wasp -g "$wasp_file" > "$output_file"
	fi

	# TEST is set to 0 if two files are the same.
	TEST=`diff -q $output_file $expected_file | wc -l`

	if [ $fail_test ] && [ "$TEST" -eq 0 ]
		then echo "SUCCESS: 	$test_name"
	elif [ ! $fail_test ] && [ "$TEST" -eq 0 ]
		then echo "SUCCESS: 	$test_name"
	else
		echo "FAIL:		$test_name"
	fi

	rm "$output_file"
done

sast_tests=$(find tests/sast -iname "*.wasp")
echo "SEMANTIC TESTS"
for file in $sast_tests; do
    get_test_name "$file"

    output_file="tests/sast/$test_name.output"
    wasp_file="tests/sast/$test_name.wasp"
    expected_file="tests/sast/$test_name.expected"

    # fail_test set to true when expected to fail
    fail_test=$(echo "$file" | grep "fail_")

    if [ $fail_test ]
        then ./wasp -s "$wasp_file" &> "$output_file"
    else
         ./wasp -s "$wasp_file" > "$output_file"
    fi

    # TEST is set to 0 if two files are the same.
    TEST=`diff -q $output_file $expected_file | wc -l`

    if [ $fail_test ] && [ "$TEST" -eq 0 ]
        then echo "SUCCESS:     $test_name"
    elif [ ! $fail_test ] && [ "$TEST" -eq 0 ]
        then echo "SUCCESS:     $test_name"
    else
        echo "FAIL:     $test_name"
    fi

    rm "$output_file"
done
