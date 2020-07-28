App = {
  web3Provider: null,
  contracts: {},
  filelock: false,

  init: async function() {

    return await App.initWeb3();
  },

  initWeb3: async function() {
    // Modern dapp browsers...
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account access
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access")
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);
    
    // write to new file
    var obj = {
      "data" : [
      ]
    }
    localStorage.setItem('bankStorage', JSON.stringify(obj));

    return App.initContract();
  },

  initContract: function() {
    $.getJSON('TenancyAgreementFactory.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var TenancyAgreementFactoryArtifact = data;
      App.contracts.TenancyAgreementFactory = TruffleContract(TenancyAgreementFactoryArtifact);

      // Set the provider for our contract
      App.contracts.TenancyAgreementFactory.setProvider(App.web3Provider);


    });

    $.getJSON('ERC20.json', function(data) {
      // Get the necessary contract artifact file aznd instantiate it with truffle-contract
      var ERC20Artifact = data;
      App.contracts.ERC20 = TruffleContract(ERC20Artifact);

      // Set the provider for our contract
      App.contracts.ERC20.setProvider(App.web3Provider);

    });
    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '#create-btn', App.handleContract);
    $(document).on('click', '#pay-btn', App.payRent);
    $(document).on('click', '#tenant-btn', App.showTenantForm);
    $(document).on('click', '.owner', App.showOwnerForm);
    $(document).on('click', '.nego', App.negotiate);
    $(document).on('click', '#manager', App.showOwnerAdd);
    $(document).on('click', '#view-btn', App.getLease);
    $(document).on('click', '#bond-btn', App.getBond);
    $(document).on('click', '#mint', App.mint);


    console.log('binding');
  },

  showOwnerAdd:function(event){
    $("#owner-add-form").css("display", "block");
  },
  // handle create new lease contract
  handleContract: function(event) {
    event.preventDefault();
    console.log('handling');
    var tenancyInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        tenancyInstance = instance;
        var tenant = $('#tenant-add').val();
        var owneradd = $('#owner-add').val();
        var rent = parseInt($('#rent').val());
        var duration = parseInt($('#duration').val());
        var bond = parseInt($('#bond').val());
        var periodic = false;
        if ($("#periodic :selected").val() == "yes"){
          periodic = true;
        }
        var hd = false;
        if ($("#holding-deposit :selected").val() == "yes"){
          hd = true;
        }
        // propose lease as manager
        if (owneradd){
          return tenancyInstance.proposeLeaseAsManager(tenant, rent,periodic, duration, hd, bond,owner, {from: account});
        }
        // propose lease as owner
        return tenancyInstance.proposeLeaseAsOwner(tenant, rent,periodic, duration, hd, bond, {from: account});
      }).then(function(result) {
        alert('create lease contract success');
      }).catch(function(err) {
        console.log('handle fail');
        console.log(err.message);
      });
    });
  },

  insertDatabase: function(tenantName, balance, pmName) {
    return new Promise(_resolve => {
      // wait for file lock 
      while (App.filelock == true) {
      }
      // a single check is fine as JS is single threaded
      App.filelock = true; // lock for following process
      var obj = JSON.parse(localStorage.getItem('bankStorage'));
      var data = {
        id : obj.data.length + 1,
        name : tenantName,
        balance : balance,
        status: unpaid
      };
      obj['data'].push(tenantData);
      // save to local storage
      localStorage.setItem('bankStorage', JSON.stringify(obj));
      // done work and unlock lock
      App.filelock = false;
      return true;
    });
  },

  UpdateDatabase: function(id, tenantName, balance) {
    return new Promise(_resolve => {
      // wait for file lock 
      while (App.filelock == true) {
      }
      // a single check is fine as JS is single threaded
      App.filelock = true; // lock for following process
      var obj = JSON.parse(localStorage.getItem('bankStorage'));
      // find user, assume name as key
      var dataArray = obj.data;
      // do a linear search
      function findId(data, id, balance) {
        var categoryArray = data.data;
        for (var i = 0; i < categoryArray.length; i++) {
            if (categoryArray[i].id == id) {
              categoryArray[i].status = paid;
              return true; 
            }
        }
        // item not found
        return false;
      }

      // save to local storage
      localStorage.setItem('bankStorage', JSON.stringify(obj));
      // done work and unlock lock
      App.filelock = false;
      return true;
    });
  },

  // Transfer ERC20 token to tenant
  mint: function() {
    // These variables are from a form
    var payAmount = 200;
    var tenantAccount = "0x627306090abaB3A6e1400e9345bC60c78a8BEf57"

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];

      // call truffle SC to pay ERC20 token to current user. 
      App.contracts.ERC20.deployed().then(function(instance) {
        ERC20Instance = instance;
        return ERC20Instance.mint(payAmount, {from: account});
      }).then(async function(result) {
        console.log('handle success');
        // insert transaction into a json file. 
        const result_database = await App.insertDatabase(tenantAccount, payAmount, account);
        console.log(result);
        return ERC20Instance.transfer(tenantAccount, payAmount, {from: account});
      }).then(function(result) {
        console.log(result);
      })
      .catch(function(err) {
        console.log('handle fail');
        console.log(err.message);
      });
    });
  },

  showTenantForm: function(event) {
      $("#tenant-form").css("display", "block");
      $("#owner-form").css("display", "none");
  },

  showOwnerForm: function(event) {
     $("#owner-form").css("display", "block");
     $("#tenant-form").css("display", "none");
  },
  // handle negotiation
  negotiate: function(event) {
    event.preventDefault();
    console.log('negotiating');
    var tenancyInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        tenancyInstance = instance;
        var negoPrice = parseInt($('#negotiate-price').val());
        var tenantAdd = parseInt($('#tenant-nego-address').val());
        console.log(account);
        // nego as tenant
        if (event.target.id == "negotiate-tenant-btn"){
          return tenancyInstance.negotiatePriceTenant(negoPrice, {from: account});
        } else {
          return tenancyInstance.negotiatePriceManagerOwner(tenantAdd,negoPrice, {from: account});
        }
      }).then(function(result) {
        alert('nego success');
      }).catch(function(err) {
        console.log('nego fail');
        console.log(err.message);
      });
    });
  },

  // handle pay rent
  payRent: function(event) {
    event.preventDefault();
    console.log('paying');
    var tenancyInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        tenancyInstance = instance;
        var rentTenant = parseInt($('#rent-tenant').val());
        var rentPrice = parseInt($('#rent-price').val());
        console.log(account);
        return tenancyInstance.payRent(rentPrice, {from: account});
      }).then(function(result) {
        alert('pay rent success');
      }).catch(function(err) {
        console.log('pay rent fail');
        console.log(err.message);
      });
    });
  },

  // sign lease
  signLease: function(event) {
    event.preventDefault();
    var tenancyInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        tenancyInstance = instance;
        return tenancyInstance.acceptLease( {from: account});
      }).then(function(result) {
        alert('lease signed!');
      }).catch(function(err) {
        console.log('sign lease fail');
        console.log(err.message);
      });
    });
  },
  // get lease info
  getLease: function(event) {
    event.preventDefault();
    var tenancyInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];

      var leaseInstance;

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        leaseInstance = instance;

        return leaseInstance.viewLeaseProposal.call();
      }).then(function(rentPerWeek, periodicLease, leaseDuration, managerAddress, ownerAddress, holdingDeposit, rentalBondInWeeks) {
        console.log(rentPerWeek);
        console.log(periodicLease);
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },
  // get lease info
  getBond: function(event) {
    event.preventDefault();
    var tenancyInstance;
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }
      var account = accounts[0];

      App.contracts.TenancyAgreementFactory.deployed().then(function(instance) {
        tenancyInstance = instance;
        return tenancyInstance.retrieveBond( {from: account});
      }).then(function(result) {
        alert('bond retrieved success');
      }).catch(function(err) {
        alert('bond fail to retrieve');
      });
    });
  },

};

!(function($) {
  "use strict";

  // Preloader
  $(window).on('load', function() {
    if ($('#preloader').length) {
      $('#preloader').delay(100).fadeOut('slow', function() {
        $(this).remove();
      });
    }
    console.log('load 2');
    App.init();
  });

  // Smooth scroll for the navigation menu and links with .scrollto classes
  var scrolltoOffset = $('#header').outerHeight() - 1;
  $(document).on('click', '.nav-menu a, .mobile-nav a, .scrollto', function(e) {
    if (location.pathname.replace(/^\//, '') == this.pathname.replace(/^\//, '') && location.hostname == this.hostname) {
      var target = $(this.hash);
      if (target.length) {
        e.preventDefault();

        var scrollto = target.offset().top - scrolltoOffset;

        if ($(this).attr("href") == '#header') {
          scrollto = 0;
        }

        $('html, body').animate({
          scrollTop: scrollto
        }, 1500, 'easeInOutExpo');

        if ($(this).parents('.nav-menu, .mobile-nav').length) {
          $('.nav-menu .active, .mobile-nav .active').removeClass('active');
          $(this).closest('li').addClass('active');
        }

        if ($('body').hasClass('mobile-nav-active')) {
          $('body').removeClass('mobile-nav-active');
          $('.mobile-nav-toggle i').toggleClass('icofont-navigation-menu icofont-close');
          $('.mobile-nav-overly').fadeOut();
        }
        return false;
      }
    }
  });

  // Activate smooth scroll on page load with hash links in the url
  $(document).ready(function() {
    // if (window.location.hash) {
    //   var initial_nav = window.location.hash;
    //   if ($(initial_nav).length) {
    //     var scrollto = $(initial_nav).offset().top - scrolltoOffset;
    //     $('html, body').animate({
    //       scrollTop: scrollto
    //     }, 1500, 'easeInOutExpo');
    //   }
    // }


  });


  // Navigation active state on scroll
  var nav_sections = $('section');
  var main_nav = $('.nav-menu, #mobile-nav');

  $(window).on('scroll', function() {
    var cur_pos = $(this).scrollTop() + 200;

    nav_sections.each(function() {
      var top = $(this).offset().top,
        bottom = top + $(this).outerHeight();

      if (cur_pos >= top && cur_pos <= bottom) {
        if (cur_pos <= bottom) {
          main_nav.find('li').removeClass('active');
        }
        main_nav.find('a[href="#' + $(this).attr('id') + '"]').parent('li').addClass('active');
      }
      if (cur_pos < 300) {
        $(".nav-menu ul:first li:first").addClass('active');
      }
    });
  });

  // Back to top button
  $(window).scroll(function() {
    if ($(this).scrollTop() > 100) {
      $('.back-to-top').fadeIn('slow');
    } else {
      $('.back-to-top').fadeOut('slow');
    }
  });

  $('.back-to-top').click(function() {
    $('html, body').animate({
      scrollTop: 0
    }, 1500, 'easeInOutExpo');
    return false;
  });

  // Init AOS
  function aos_init() {
    AOS.init({
      duration: 1000,
      once: true
    });
  }
  $(window).on('load', function() {
    aos_init();
  });

})(jQuery);
