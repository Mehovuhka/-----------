// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Shopes{

    struct users{
        address address_user;
        uint role; // 0 - покупатель, 1 - администратор, 2 - продавец
        uint ActiveRole; // текущая роль
    }
    
    struct reqestDown{
        uint256 id;
        address user;
        address shope; // где работает
        bool status; // status - статус расмотрения админом. По умолчанию false.
        uint approval; // approval - одобрение или откланение админом повышения ролию 0 - ещё не решено, 1 - отказ, 2 - одобрен
    }

    struct reqestUp{ // заявка на повышение 
        uint256 id;
        address user;
        address shope; // где хочет работать 
        bool status; // status - статус расмотрения админом. По умолчанию false.
        uint approval; // approval - одобрение или откланение админом повышения ролию 0 - ещё не решено, 1 - отказ, 2 - одобрен
    }

    struct otziv{ // книга отзывов
        address creator;
        uint Ocenka;
        string comment;
        reactions[] React;
        answers[] Answers;
    }

    struct answers{ // комменатрии других пользователей
        address creator;
        string comment;
        reactions[] React;
    }

    struct reactions{
        address user;
        uint reaction; // 0 - лайк, 1 - дизлайк
    }

    struct shop{
        string name_shop;
        address address_shop;
        otziv[] Otziv; // книга отзывов
        address[] workers; // работники
    }

    users[] Users;
    shop[] Shop;
    reqestUp[] ReqestUp;
    reqestDown[] ReqestDown;

    constructor(){
        Users.push(users(0x83A1C4FB921Eb488bd6cFf6008FbeE2c70d6451d, 1, 1)); // admin
        Users.push(users(0xf66540d913619e93Af8985326BE718A10Be7A681, 0, 0)); // users
        Users.push(users(0x4Ff3C34D2799722a1bf6eCC0082aC0b941c4cDB3, 0, 0));
    }

    // modifiers
    modifier isNotRegistered(address user){
        bool isReg = false;
        for(uint i = 0; i < Users.length; i++){
            if(Users[i].address_user == user){
                isReg = true;
            }
        }
        require(isReg, "101"); // error 101 - not registred
        _;
    }

    modifier isAdmin(address user){
        bool isAdm = false;
        for(uint i = 0; i < Users.length; i++){
            if(Users[i].address_user == user){
                if(Users[i].role == 1){
                    isAdm = true;
                }
            }
        }
        require(isAdm, "102"); // error 102 - not admin
        _;
    }

    modifier isRegistered(address user){
        for(uint i = 0; i < Users.length; i++){
            require(Users[i].address_user !=user, "103"); // error 103 - already registered user
        }
        _;
    }

    modifier shopIsExists(address newShop) {
        for (uint i = 0; i < Users.length; i++) {
            require(Users[i].address_user != newShop, "104"); // error 104 - shop is exists
        }
        _;
    }

    modifier shopIsNotExists(address shope) {
        for (uint i = 0; i < Shop.length; i++) {
            require(Shop[i].address_shop == shope, "105"); // error 105 - shop is not exists
        }
        _;
    }

    modifier isNotAdmin(address user){
        bool isNotAdm = false;
        for(uint i = 0; i < Users.length; i++){
            if(Users[i].address_user == user){
                if(Users[i].role != 1){
                    isNotAdm = true;
                }
            }
        }
        require(isNotAdm, "106"); // error 106 - already admin
        _;
    }

    modifier isBuyer(address user){
        bool isBuyr = false;
        for(uint i = 0; i < Users.length; i++){
            if(Users[i].address_user == user){
                if(Users[i].ActiveRole == 0){
                    isBuyr = true;
                }
            }
        }
        require(isBuyr, "107"); // error 107 - not buyer
        _;
    }

    // admins functions
    function roleChange(address user, uint role) public isAdmin(msg.sender){
        for(uint id = 0; id < Users.length; id++){
            if(Users[id].address_user == user){
                require(Users[id].role != role, "201"); // error 201 - already has this role
                Users[id].role = role;
                Users[id].ActiveRole = role;
            }
        }
    }

    function addNewAdmin(address user) public isAdmin(msg.sender) isNotRegistered(user) isNotAdmin(user){
        for(uint id = 0; id < Users.length; id++){
            if(Users[id].address_user == user){
                Users[id].role = 1;
                Users[id].ActiveRole = 1;
            }
        }
    }

    function regNewShop(address newShop, string memory nameShop) public isAdmin(msg.sender){
        require(newShop != address(0), "213"); // error 213 - address new shop not null 
        shop storage new_shop = Shop.push();
        new_shop.name_shop = nameShop;
        new_shop.address_shop = newShop;
    }

    function deleteShop(address shope) public isAdmin(msg.sender){
        for(uint id = 0; id < Shop.length; id++){
            if(Shop[id].address_shop == shope){
                for(uint idW; idW < Shop[id].workers.length; idW++){
                    for(uint idU = 0; idU < Users.length; idU++){
                        if(Users[idU].address_user == Shop[id].workers[idW]){
                            Users[idU].role = 0;
                            Users[idU].ActiveRole = 0;
                        }
                    }
                }
                delete Shop[id];
            }
        }
    }

    function checkReqestInSeller(uint idReqest, uint adminAnswer) public isAdmin(msg.sender){
        // require(ReqestUp[idReqest].status != true, "208"); // error 208 - reqest has already been considered
        require(adminAnswer < 3, "209"); // error 209 - there is no such answer
        ReqestUp[idReqest].status = true;
        require(adminAnswer != 0, "210"); // error 210 - you need to reject or approve the application
        ReqestUp[idReqest].approval = adminAnswer;
    }

    function addNewSeller(uint idReqest) public isAdmin(msg.sender){
        require(ReqestUp[idReqest].status != false, "211"); // error 211 - reqest has not been considered
        if(ReqestUp[idReqest].approval == 2){
            for(uint id = 0; id < Users.length; id++){
                if(Users[id].address_user == ReqestUp[idReqest].user){
                    Users[id].role = 2;
                    Users[id].ActiveRole = 2;
                    for(uint idS = 0; idS < Shop.length; idS++){
                        if(Shop[idS].address_shop == ReqestUp[idReqest].shope){
                            Shop[idS].workers.push(ReqestUp[idReqest].user);
                        }
                    }
                }    
            }
        }
    }
    
    function checkReqestDownSeller(uint idReqest, uint adminAnswer) public isAdmin(msg.sender){
        require(ReqestDown[idReqest].status != true, "208"); // error 208 - reqest has already been considered
        require(adminAnswer < 3, "209"); // error 209 - there is no such answer
        ReqestDown[idReqest].status = true;
        require(adminAnswer != 0, "210"); // error 210 - you need to reject or approve the application
        ReqestDown[idReqest].approval = adminAnswer;
    }

    function deleteSeller(uint idReqest) public isAdmin(msg.sender){
        require(ReqestDown[idReqest].status != false, "211"); // error 211 - reqest has not been considered
        if(ReqestDown[idReqest].approval == 2){
            for(uint id = 0; id < Users.length; id++){
                if(Users[id].address_user == ReqestDown[idReqest].user){
                    Users[id].role = 0;
                    Users[id].ActiveRole = 0;
                    for(uint idS = 0; idS < Shop.length; idS++){
                        if(Shop[idS].address_shop == ReqestDown[idReqest].shope){
                            for(uint idW = 0; idW < Shop[idS].workers.length; idW++){
                                if(Shop[idS].workers[idW] == Users[id].address_user){
                                    delete Shop[idS].workers[idW];
                                }
                            }
                        }
                    }
                }     
            }
        }
    }

    // all functions
    function regNewUser(address newUser) public isRegistered(newUser){
        Users.push(users(newUser, 0, 0));
    }

    function roleSwitch(address user) public isNotRegistered(msg.sender){
        for(uint id = 0; id < Users.length; id++){
            if(Users[id].address_user == user){
                if(Users[id].ActiveRole == 0){
                require(Users[id].role != 0, "206"); // error 206 - already have role = 0(buyer)
                if(Users[id].role == 1){
                    Users[id].ActiveRole = 1;
                }
                if(Users[id].role == 2){
                    Users[id].ActiveRole = 2;
                }
                } else{
                    Users[id].ActiveRole = 0;
                }
            }        
        }
    }

    function feedback(address shope, uint ocenka, string memory comm)public isBuyer(msg.sender) isNotRegistered(msg.sender){
        for(uint id = 0; id < Shop.length; id++){
            if(Shop[id].address_shop == shope){
                for(uint idW = 0; idW < Shop[id].workers.length; idW++){
                    require(msg.sender != Shop[id].workers[idW], "203"); // error 203 - a store employee cannot leave a review on his store
                }
                otziv storage newOtziv = Shop[id].Otziv.push();
                newOtziv.creator = msg.sender;
                newOtziv.Ocenka = ocenka;
                newOtziv.comment = comm;
            }  
        }
    }

    function addCommentForFeedback(address shope, uint idOtziv, string memory comm) public isNotRegistered(msg.sender){
        for(uint id = 0; id < Shop.length; id++){
            if(Shop[id].address_shop == shope){
                answers storage newAnswer = Shop[id].Otziv[idOtziv].Answers.push();
                newAnswer.creator = msg.sender;
                newAnswer.comment = comm;
            }  
        }
    }

    function addReactionForOtziv(address shope, uint idOtziv, uint reacti) public isNotRegistered(msg.sender){
        require(reacti < 2, "204"); // error 204 - there is no such reaction in reaction for Otziv
        for(uint id = 0; id < Shop.length; id++){
            if(Shop[id].address_shop == shope){
                reactions storage newReaction = Shop[id].Otziv[idOtziv].React.push();
                newReaction.user = msg.sender;
                newReaction.reaction = reacti;
            }
        }
    }

    function addReactionForAnswer(address shope, uint idOtziv, uint idAnswer, uint reacti) public isNotRegistered(msg.sender){
        require(reacti < 2, "205"); // error 205 - there is no such reaction in reaction for Answer
        for(uint id = 0; id < Shop.length; id++){
            if(Shop[id].address_shop == shope){
                reactions storage newReaction = Shop[id].Otziv[idOtziv].Answers[idAnswer].React.push();
                newReaction.user = msg.sender;
                newReaction.reaction = reacti;
            } 
        }
    }

    function addReqestInSeller(address shope) public isNotRegistered(msg.sender){
        for(uint256 id = 0; id < Users.length; id++){
            if(Users[id].address_user == msg.sender){
                require(Users[id].role != 2, "207"); // error 207 - you already have role seller
                ReqestUp.push(reqestUp(ReqestUp.length, msg.sender, shope, false, 0));
            } 
        }
    }

    function addReqestDownSeller(address shope) public isNotRegistered(msg.sender){
        for(uint256 id = 0; id < Users.length; id++){
            if(Users[id].address_user == msg.sender){
                require(Users[id].role == 2, "212"); // error 212 - you dont already have role seller
                ReqestDown.push(reqestDown(ReqestDown.length, msg.sender, shope, false, 0));
            }
        }
    }
    
    // view functions
    function view_Shops() public view returns (shop[] memory) {
        return (Shop);
    }

    function view_Users() public view returns (users[] memory) {
        return (Users);
    }

    function view_ReqestsUp() public view returns (reqestUp[] memory) {
        return (ReqestUp);
    }

    function view_ReqestsDown() public view returns (reqestDown[] memory) {
        return (ReqestDown);
    }

}