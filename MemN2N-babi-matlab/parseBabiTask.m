% Copyright (c) 2015-present, Facebook, Inc.
% All rights reserved.
%
% This source code is licensed under the BSD-style license found in the
% LICENSE file in the root directory of this source tree. An additional grant 
% of patent rights can be found in the PATENTS file in the same directory.

function [story, questions, qstory] = parseBabiTask(data_path, dict, include_question)
story = zeros(20, 1000, 1000, 'single');
story_ind = 0;
sentence_ind = 0;
max_words = 0;
max_sentences = 0;

questions = zeros(10, 1000, 'single');
question_ind = 0;

qstory = zeros(20, 1000, 'single');

fi = 1;
fd = fopen(data_path{fi});
line_ind = 0;

while true
    line = fgets(fd);
    % If there are no more characters
    if ischar(line) == false
        fclose(fd);
        % In case there are more files to read in the data_path
        if fi < length(data_path)
            fi = fi + 1;
            fd = fopen(data_path{fi});
            line_ind = 0;
            line = fgets(fd);
        else
            break
        end
    end
    line_ind = line_ind + 1; % starting the line_ind from 1
    % The output of words = textscan(line, '%s') would be a 6x1 cell 
    % for the following sentence: "1 Mary moved to the bathroom."
    % with items: [1, Mary, moved, to, the, bathroom.]'
    words = textscan(line, '%s'); 
    % words{1} is the first column of words cell
    % including the same [1, Mary, moved, to, the, bathroom.]' information
    words = words{1};
    
    % Comparing first element of words with '1'
    % In this case, first element is '1'
    % '1' basically means start of a new story
    if strcmp(words{1}, '1')
        story_ind = story_ind + 1; % Updated story index
        sentence_ind = 0;
        map = [];
    end

    % line == '?' creates a 1x[char-count] (e.g. 1x30) vector
    % if element ith is equal to char. '?', then it will be 1
    % if sum of all elements is zero, it is not a question
    if sum(line == '?') == 0
        is_question = false;
        sentence_ind = sentence_ind + 1;
    else        
        is_question = true;
        question_ind = question_ind + 1;
        % TODO: why storing in index 1 and 2?
        questions(1,question_ind) = story_ind;
        questions(2,question_ind) = sentence_ind;
        % TODO: Including question in sentence counting?
        if include_question
            sentence_ind = sentence_ind + 1;
        end
    end
    
    % end+1 is used to grow the array
    map(end+1) = sentence_ind;

    % Going through each word of words array, except the number 
    for k = 2:length(words);
        w = words{k};
        w = lower(w); % lowercase
        % Removing '.' and '?' characters
        if w(end) == '.' || w(end) == '?'
            w = w(1:end-1);
        end 
        % Does dict keys exclude w word?
        % If yes, add w key with value of dict length plus one
        % which is number of words so far + 1
        % TODO: why? Related to BoW?
        if isKey(dict, w) == false
            dict(w) = length(dict) + 1;
        end        
        max_words = max(max_words, k-1);
        
        if is_question == false
            % starting index from 1
            story(k-1, sentence_ind, story_ind) = dict(w);
        else
            qstory(k-1, question_ind) = dict(w);
            % Including question in story or not
            if include_question == true
                story(k-1, sentence_ind, story_ind) = dict(w);
            end            
            
            % Because of structure of stories
            % "12 Where is Daniel? 	office	11"
            % Next word after the question mark is the answer
            if words{k}(end) == '?'
                answer = words{k+1};
                answer = lower(answer);
                if isKey(dict, answer) == false
                    dict(answer) = length(dict) + 1;
                end
                questions(3,question_ind) = dict(answer);
                % Getting the supporting fact sentence numbers
                % Example (21 and 10): "22 Where is the apple? 	hallway	21 10"
                % map(str2num(words{h})) gives the associated sentence index
                for h = k+2:length(words)
                    questions(2+h-k,question_ind) = map(str2num(words{h}));
                end
                questions(10,question_ind) = line_ind;
                break
            end
        end
    end
    max_sentences = max(max_sentences, sentence_ind);
end
story = story(1:max_words, 1:max_sentences, 1:story_ind);
questions = questions(:,1:question_ind);
qstory = qstory(1:max_words,1:question_ind);

story(story == 0) = dict('nil');
qstory(qstory == 0) = dict('nil');
end