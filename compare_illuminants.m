% function compare_illuminants      

    clear
    clc

    %%
    
    L = 400 : 5 : 700; % nm
    
    col = 'rbgkcm';
    
    %%
    
    figure(91)
        clf
        hold on
        set(gcf,'color','white')
    
    %%
    
    for i = 1 : 6

        switch i

            case 1 % 
                desc = 'A';
                lambda = [300 301 302 303 304 305 306 307 308 309 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324 325 326 327 328 329 330 331 332 333 334 335 336 337 338 339 340 341 342 343 344 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 362 363 364 365 366 367 368 369 370 371 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 387 388 389 390 391 392 393 394 395 396 397 398 399 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 419 420 421 422 423 424 425 426 427 428 429 430 431 432 433 434 435 436 437 438 439 440 441 442 443 444 445 446 447 448 449 450 451 452 453 454 455 456 457 458 459 460 461 462 463 464 465 466 467 468 469 470 471 472 473 474 475 476 477 478 479 480 481 482 483 484 485 486 487 488 489 490 491 492 493 494 495 496 497 498 499 500 501 502 503 504 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 536 537 538 539 540 541 542 543 544 545 546 547 548 549 550 551 552 553 554 555 556 557 558 559 560 561 562 563 564 565 566 567 568 569 570 571 572 573 574 575 576 577 578 579 580 581 582 583 584 585 586 587 588 589 590 591 592 593 594 595 596 597 598 599 600 601 602 603 604 605 606 607 608 609 610 611 612 613 614 615 616 617 618 619 620 621 622 623 624 625 626 627 628 629 630 631 632 633 634 635 636 637 638 639 640 641 642 643 644 645 646 647 648 649 650 651 652 653 654 655 656 657 658 659 660 661 662 663 664 665 666 667 668 669 670 671 672 673 674 675 676 677 678 679 680 681 682 683 684 685 686 687 688 689 690 691 692 693 694 695 696 697 698 699 700 701 702 703 704 705 706 707 708 709 710 711 712 713 714 715 716 717 718 719 720 721 722 723 724 725 726 727 728 729 730 731 732 733 734 735 736 737 738 739 740 741 742 743 744 745 746 747 748 749 750 751 752 753 754 755 756 757 758 759 760 761 762 763 764 765 766 767 768 769 770 771 772 773 774 775 776 777 778 779 780 781 782 783 784 785 786 787 788 789 790 791 792 793 794 795 796 797 798 799 800 801 802 803 804 805 806 807 808 809 810 811 812 813 814 815 816 817 818 819 820 821 822 823 824 825 826 827 828 829 830];
                power  = [0.930483 0.967643 1.00597 1.04549 1.08623 1.12821 1.17147 1.21602 1.26188 1.3091 1.35769 1.40768 1.4591 1.51198 1.56633 1.62219 1.67959 1.73855 1.7991 1.86127 1.92508 1.99057 2.05776 2.12667 2.19734 2.2698 2.34406 2.42017 2.49814 2.57801 2.65981 2.74355 2.82928 2.91701 3.00678 3.09861 3.19253 3.28857 3.38676 3.48712 3.58968 3.69447 3.80152 3.91085 4.0225 4.13648 4.25282 4.37156 4.49272 4.61631 4.74238 4.87095 5.00204 5.13568 5.27189 5.4107 5.55213 5.69622 5.84298 5.99244 6.14462 6.29955 6.45724 6.61774 6.78105 6.9472 7.11621 7.28811 7.46292 7.64066 7.82135 8.00501 8.19167 8.38134 8.57404 8.7698 8.96864 9.17056 9.37561 9.58378 9.7951 10.0096 10.2273 10.4481 10.6722 10.8996 11.1302 11.364 11.6012 11.8416 12.0853 12.3324 12.5828 12.8366 13.0938 13.3543 13.6182 13.8855 14.1563 14.4304 14.708 14.9891 15.2736 15.5616 15.853 16.148 16.4464 16.7484 17.0538 17.3628 17.6753 17.9913 18.3108 18.6339 18.9605 19.2907 19.6244 19.9617 20.3026 20.647 20.995 21.3465 21.7016 22.0603 22.4225 22.7883 23.1577 23.5307 23.9072 24.2873 24.6709 25.0581 25.4489 25.8432 26.2411 26.6425 27.0475 27.456 27.8681 28.2836 28.7027 29.1253 29.5515 29.9811 30.4142 30.8508 31.2909 31.7345 32.1815 32.632 33.0859 33.5432 34.004 34.4682 34.9358 35.4068 35.8811 36.3588 36.8399 37.3243 37.8121 38.3031 38.7975 39.2951 39.796 40.3002 40.8076 41.3182 41.832 42.3491 42.8693 43.3926 43.9192 44.4488 44.9816 45.5174 46.0563 46.5983 47.1433 47.6913 48.2423 48.7963 49.3533 49.9132 50.476 51.0418 51.6104 52.1818 52.7561 53.3332 53.9132 54.4958 55.0813 55.6694 56.2603 56.8539 57.4501 58.0489 58.6504 59.2545 59.8611 60.4703 61.082 61.6962 62.3128 62.932 63.5535 64.1775 64.8038 65.4325 66.0635 66.6968 67.3324 67.9702 68.6102 69.2525 69.8969 70.5435 71.1922 71.843 72.4959 73.1508 73.8077 74.4666 75.1275 75.7903 76.4551 77.1217 77.7902 78.4605 79.1326 79.8065 80.4821 81.1595 81.8386 82.5193 83.2017 83.8856 84.5712 85.2584 85.947 86.6372 87.3288 88.0219 88.7165 89.4124 90.1097 90.8083 91.5082 92.2095 92.912 93.6157 94.3206 95.0267 95.7339 96.4423 97.1518 97.8623 98.5739 99.2864 100 100.715 101.43 102.146 102.864 103.582 104.301 105.02 105.741 106.462 107.184 107.906 108.63 109.354 110.078 110.803 111.529 112.255 112.982 113.709 114.436 115.164 115.893 116.622 117.351 118.08 118.81 119.54 120.27 121.001 121.731 122.462 123.193 123.924 124.655 125.386 126.118 126.849 127.58 128.312 129.043 129.774 130.505 131.236 131.966 132.697 133.427 134.157 134.887 135.617 136.346 137.075 137.804 138.532 139.26 139.988 140.715 141.441 142.167 142.893 143.618 144.343 145.067 145.79 146.513 147.235 147.957 148.678 149.398 150.117 150.836 151.554 152.271 152.988 153.704 154.418 155.132 155.845 156.558 157.269 157.979 158.689 159.397 160.104 160.811 161.516 162.221 162.924 163.626 164.327 165.028 165.726 166.424 167.121 167.816 168.51 169.203 169.895 170.586 171.275 171.963 172.65 173.335 174.019 174.702 175.383 176.063 176.741 177.419 178.094 178.769 179.441 180.113 180.783 181.451 182.118 182.783 183.447 184.109 184.77 185.429 186.087 186.743 187.397 188.05 188.701 189.35 189.998 190.644 191.288 191.931 192.572 193.211 193.849 194.484 195.118 195.75 196.381 197.009 197.636 198.261 198.884 199.506 200.125 200.743 201.359 201.972 202.584 203.195 203.803 204.409 205.013 205.616 206.216 206.815 207.411 208.006 208.599 209.189 209.778 210.365 210.949 211.532 212.112 212.691 213.268 213.842 214.415 214.985 215.553 216.12 216.684 217.246 217.806 218.364 218.92 219.473 220.025 220.574 221.122 221.667 222.21 222.751 223.29 223.826 224.361 224.893 225.423 225.951 226.477 227 227.522 228.041 228.558 229.073 229.585 230.096 230.604 231.11 231.614 232.115 232.615 233.112 233.606 234.099 234.589 235.078 235.564 236.047 236.529 237.008 237.485 237.959 238.432 238.902 239.37 239.836 240.299 240.76 241.219 241.675 242.13 242.582 243.031 243.479 243.924 244.367 244.808 245.246 245.682 246.116 246.548 246.977 247.404 247.829 248.251 248.671 249.089 249.505 249.918 250.329 250.738 251.144 251.548 251.95 252.35 252.747 253.142 253.535 253.925 254.314 254.7 255.083 255.465 255.844 256.221 256.595 256.968 257.338 257.706 258.071 258.434 258.795 259.154 259.511 259.865 260.217 260.567 260.914 261.259 261.602];

            case 2 % 
                desc = 'C';
                lambda = [300 305 310 315 320 325 330 335 340 345 350 355 360 365 370 375 380 385 390 395 400 405 410 415 420 425 430 435 440 445 450 455 460 465 470 475 480 485 490 495 500 505 510 515 520 525 530 535 540 545 550 555 560 565 570 575 580 585 590 595 600 605 610 615 620 625 630 635 640 645 650 655 660 665 670 675 680 685 690 695 700 705 710 715 720 725 730 735 740 745 750 755 760 765 770 775 780];
                power  = [0 0 0 0 0.01 0.2 0.4 1.55 2.7 4.85 7 9.95 12.9 17.2 21.4 27.5 33 39.92 47.4 55.17 63.3 71.81 80.6 89.53 98.1 105.8 112.4 117.75 121.5 123.45 124 123.6 123.1 123.3 123.8 124.09 123.9 122.92 120.7 116.9 112.1 106.98 102.3 98.81 96.9 96.78 98 99.94 102.1 103.95 105.2 105.67 105.3 104.11 102.3 100.15 97.8 95.43 93.2 91.22 89.7 88.83 88.4 88.19 88.1 88.06 88 87.86 87.8 87.99 88.2 88.2 87.9 87.22 86.3 85.3 84 82.21 80.2 78.24 76.3 74.36 72.4 70.4 68.3 66.3 64.4 62.8 61.5 60.2 59.2 58.5 58.1 58 58.2 58.5 59.1];

            case 3 % 
                desc = 'D50';
                lambda = [300 305 310 315 320 325 330 335 340 345 350 355 360 365 370 375 380 385 390 395 400 405 410 415 420 425 430 435 440 445 450 455 460 465 470 475 480 485 490 495 500 505 510 515 520 525 530 535 540 545 550 555 560 565 570 575 580 585 590 595 600 605 610 615 620 625 630 635 640 645 650 655 660 665 670 675 680 685 690 695 700 705 710 715 720 725 730 735 740 745 750 755 760 765 770 775 780];
                power  = [0.019 1.035 2.051 4.914 7.778 11.263 14.748 16.348 17.948 19.479 21.01 22.476 23.942 25.451 26.961 25.724 24.488 27.179 29.871 39.589 49.308 52.91 56.513 58.273 60.034 58.926 57.818 66.321 74.825 81.036 87.247 88.93 90.612 90.99 91.368 93.238 95.109 93.536 91.963 93.843 95.724 96.169 96.613 96.871 97.129 99.614 102.099 101.427 100.755 101.536 102.317 101.159 100 98.868 97.735 98.327 98.918 96.208 93.499 95.593 97.688 98.478 99.269 99.155 99.042 97.382 95.722 97.29 98.857 97.262 95.667 96.929 98.19 100.597 103.003 101.068 99.133 93.257 87.381 89.492 91.604 92.246 92.889 84.872 76.854 81.683 86.511 89.546 92.58 85.405 78.23 67.961 57.692 70.307 82.923 80.599 78.274];

            case 4 % 
                desc = 'D55';
                lambda = [300 305 310 315 320 325 330 335 340 345 350 355 360 365 370 375 380 385 390 395 400 405 410 415 420 425 430 435 440 445 450 455 460 465 470 475 480 485 490 495 500 505 510 515 520 525 530 535 540 545 550 555 560 565 570 575 580 585 590 595 600 605 610 615 620 625 630 635 640 645 650 655 660 665 670 675 680 685 690 695 700 705 710 715 720 725 730 735 740 745 750 755 760 765 770 775 780];
                power  = [0.024 1.048 2.072 6.648 11.224 15.936 20.647 22.266 23.885 25.851 27.817 29.219 30.621 32.464 34.308 33.446 32.584 35.335 38.087 49.518 60.949 64.751 68.554 70.065 71.577 69.746 67.914 76.76 85.605 91.799 97.993 99.228 100.463 100.188 99.913 101.326 102.739 100.409 98.078 99.379 100.68 100.688 100.695 100.341 99.987 102.098 104.21 103.156 102.102 102.535 102.968 101.484 100 98.608 97.216 97.482 97.749 94.59 91.432 92.926 94.419 94.78 95.14 94.68 94.22 92.334 90.448 91.389 92.33 90.592 88.854 89.586 90.317 92.133 93.95 91.953 89.956 84.817 79.677 81.258 82.84 83.842 84.844 77.539 70.235 74.768 79.301 82.147 84.993 78.437 71.88 62.337 52.793 64.36 75.927 73.872 71.818];

            case 5 % 
                desc = 'D65';
                lambda = [300 301 302 303 304 305 306 307 308 309 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324 325 326 327 328 329 330 331 332 333 334 335 336 337 338 339 340 341 342 343 344 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 362 363 364 365 366 367 368 369 370 371 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 387 388 389 390 391 392 393 394 395 396 397 398 399 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 419 420 421 422 423 424 425 426 427 428 429 430 431 432 433 434 435 436 437 438 439 440 441 442 443 444 445 446 447 448 449 450 451 452 453 454 455 456 457 458 459 460 461 462 463 464 465 466 467 468 469 470 471 472 473 474 475 476 477 478 479 480 481 482 483 484 485 486 487 488 489 490 491 492 493 494 495 496 497 498 499 500 501 502 503 504 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 536 537 538 539 540 541 542 543 544 545 546 547 548 549 550 551 552 553 554 555 556 557 558 559 560 561 562 563 564 565 566 567 568 569 570 571 572 573 574 575 576 577 578 579 580 581 582 583 584 585 586 587 588 589 590 591 592 593 594 595 596 597 598 599 600 601 602 603 604 605 606 607 608 609 610 611 612 613 614 615 616 617 618 619 620 621 622 623 624 625 626 627 628 629 630 631 632 633 634 635 636 637 638 639 640 641 642 643 644 645 646 647 648 649 650 651 652 653 654 655 656 657 658 659 660 661 662 663 664 665 666 667 668 669 670 671 672 673 674 675 676 677 678 679 680 681 682 683 684 685 686 687 688 689 690 691 692 693 694 695 696 697 698 699 700 701 702 703 704 705 706 707 708 709 710 711 712 713 714 715 716 717 718 719 720 721 722 723 724 725 726 727 728 729 730 731 732 733 734 735 736 737 738 739 740 741 742 743 744 745 746 747 748 749 750 751 752 753 754 755 756 757 758 759 760 761 762 763 764 765 766 767 768 769 770 771 772 773 774 775 776 777 778 779 780 781 782 783 784 785 786 787 788 789 790 791 792 793 794 795 796 797 798 799 800 801 802 803 804 805 806 807 808 809 810 811 812 813 814 815 816 817 818 819 820 821 822 823 824 825 826 827 828 829 830];
                power  = [0.0341 0.36014 0.68618 1.01222 1.33826 1.6643 1.99034 2.31638 2.64242 2.96846 3.2945 4.98865 6.6828 8.37695 10.0711 11.7652 13.4594 15.1535 16.8477 18.5418 20.236 21.9177 23.5995 25.2812 26.963 28.6447 30.3265 32.0082 33.69 35.3717 37.0535 37.343 37.6326 37.9221 38.2116 38.5011 38.7907 39.0802 39.3697 39.6593 39.9488 40.4451 40.9414 41.4377 41.934 42.4302 42.9265 43.4228 43.9191 44.4154 44.9117 45.0844 45.257 45.4297 45.6023 45.775 45.9477 46.1203 46.293 46.4656 46.6383 47.1834 47.7285 48.2735 48.8186 49.3637 49.9088 50.4539 50.9989 51.544 52.0891 51.8777 51.6664 51.455 51.2437 51.0323 50.8209 50.6096 50.3982 50.1869 49.9755 50.4428 50.91 51.3773 51.8446 52.3118 52.7791 53.2464 53.7137 54.1809 54.6482 57.4589 60.2695 63.0802 65.8909 68.7015 71.5122 74.3229 77.1336 79.9442 82.7549 83.628 84.5011 85.3742 86.2473 87.1204 87.9936 88.8667 89.7398 90.6129 91.486 91.6806 91.8752 92.0697 92.2643 92.4589 92.6535 92.8481 93.0426 93.2372 93.4318 92.7568 92.0819 91.4069 90.732 90.057 89.3821 88.7071 88.0322 87.3572 86.6823 88.5006 90.3188 92.1371 93.9554 95.7736 97.5919 99.4102 101.228 103.047 104.865 106.079 107.294 108.508 109.722 110.936 112.151 113.365 114.579 115.794 117.008 117.088 117.169 117.249 117.33 117.41 117.49 117.571 117.651 117.732 117.812 117.517 117.222 116.927 116.632 116.336 116.041 115.746 115.451 115.156 114.861 114.967 115.073 115.18 115.286 115.392 115.498 115.604 115.711 115.817 115.923 115.212 114.501 113.789 113.078 112.367 111.656 110.945 110.233 109.522 108.811 108.865 108.92 108.974 109.028 109.082 109.137 109.191 109.245 109.3 109.354 109.199 109.044 108.888 108.733 108.578 108.423 108.268 108.112 107.957 107.802 107.501 107.2 106.898 106.597 106.296 105.995 105.694 105.392 105.091 104.79 105.08 105.37 105.66 105.95 106.239 106.529 106.819 107.109 107.399 107.689 107.361 107.032 106.704 106.375 106.047 105.719 105.39 105.062 104.733 104.405 104.369 104.333 104.297 104.261 104.225 104.19 104.154 104.118 104.082 104.046 103.641 103.237 102.832 102.428 102.023 101.618 101.214 100.809 100.405 100 99.6334 99.2668 98.9003 98.5337 98.1671 97.8005 97.4339 97.0674 96.7008 96.3342 96.2796 96.225 96.1703 96.1157 96.0611 96.0065 95.9519 95.8972 95.8426 95.788 95.0778 94.3675 93.6573 92.947 92.2368 91.5266 90.8163 90.1061 89.3958 88.6856 88.8177 88.9497 89.0818 89.2138 89.3459 89.478 89.61 89.7421 89.8741 90.0062 89.9655 89.9248 89.8841 89.8434 89.8026 89.7619 89.7212 89.6805 89.6398 89.5991 89.4091 89.219 89.029 88.8389 88.6489 88.4589 88.2688 88.0788 87.8887 87.6987 87.2577 86.8167 86.3757 85.9347 85.4936 85.0526 84.6116 84.1706 83.7296 83.2886 83.3297 83.3707 83.4118 83.4528 83.4939 83.535 83.576 83.6171 83.6581 83.6992 83.332 82.9647 82.5975 82.2302 81.863 81.4958 81.1285 80.7613 80.394 80.0268 80.0456 80.0644 80.0831 80.1019 80.1207 80.1395 80.1583 80.177 80.1958 80.2146 80.4209 80.6272 80.8336 81.0399 81.2462 81.4525 81.6588 81.8652 82.0715 82.2778 81.8784 81.4791 81.0797 80.6804 80.281 79.8816 79.4823 79.0829 78.6836 78.2842 77.4279 76.5716 75.7153 74.859 74.0027 73.1465 72.2902 71.4339 70.5776 69.7213 69.9101 70.0989 70.2876 70.4764 70.6652 70.854 71.0428 71.2315 71.4203 71.6091 71.8831 72.1571 72.4311 72.7051 72.979 73.253 73.527 73.801 74.075 74.349 73.0745 71.8 70.5255 69.251 67.9765 66.702 65.4275 64.153 62.8785 61.604 62.4322 63.2603 64.0885 64.9166 65.7448 66.573 67.4011 68.2293 69.0574 69.8856 70.4057 70.9259 71.446 71.9662 72.4863 73.0064 73.5266 74.0467 74.5669 75.087 73.9376 72.7881 71.6387 70.4893 69.3398 68.1904 67.041 65.8916 64.7421 63.5927 61.8752 60.1578 58.4403 56.7229 55.0054 53.288 51.5705 49.8531 48.1356 46.4182 48.4569 50.4956 52.5344 54.5731 56.6118 58.6505 60.6892 62.728 64.7667 66.8054 66.4631 66.1209 65.7786 65.4364 65.0941 64.7518 64.4096 64.0673 63.7251 63.3828 63.4749 63.567 63.6592 63.7513 63.8434 63.9355 64.0276 64.1198 64.2119 64.304 63.8188 63.3336 62.8484 62.3632 61.8779 61.3927 60.9075 60.4223 59.9371 59.4519 58.7026 57.9533 57.204 56.4547 55.7054 54.9562 54.2069 53.4576 52.7083 51.959 52.5072 53.0553 53.6035 54.1516 54.6998 55.248 55.7961 56.3443 56.8924 57.4406 57.7278 58.015 58.3022 58.5894 58.8765 59.1637 59.4509 59.7381 60.0253 60.3125];

            case 6 % 
                desc = 'D75';
                lambda = [300 305 310 315 320 325 330 335 340 345 350 355 360 365 370 375 380 385 390 395 400 405 410 415 420 425 430 435 440 445 450 455 460 465 470 475 480 485 490 495 500 505 510 515 520 525 530 535 540 545 550 555 560 565 570 575 580 585 590 595 600 605 610 615 620 625 630 635 640 645 650 655 660 665 670 675 680 685 690 695 700 705 710 715 720 725 730 735 740 745 750 755 760 765 770 775 780];
                power  = [0.043 2.588 5.133 17.47 29.808 42.369 54.93 56.095 57.259 60 62.74 62.861 62.982 66.647 70.312 68.507 66.703 68.333 69.963 85.946 101.929 106.911 111.894 112.346 112.798 107.945 103.092 112.145 121.198 127.104 133.01 132.682 132.355 129.838 127.322 127.061 126.8 122.291 117.783 117.186 116.589 115.146 113.702 111.181 108.659 109.552 110.445 108.367 106.289 105.596 104.904 102.452 100 97.808 95.616 94.914 94.213 90.605 86.997 87.112 87.227 86.684 86.14 84.861 83.581 81.164 78.747 78.587 78.428 76.614 74.801 74.562 74.324 74.873 75.422 73.499 71.576 67.714 63.852 64.464 65.076 66.573 68.07 62.256 56.443 60.343 64.242 66.697 69.151 63.89 58.629 50.623 42.617 51.985 61.352 59.838 58.324];

    %         case 7 % 
    %             desc = 'Equal Intensity';
    %             lambda = [0 1000];
    %             power  = [1, 1];

        end
        
        y = interp1(lambda, power, L);
        
        plot(L, y, col(i),'LineWidth',2)
        
    end
    
    xlim([min(L) max(L)])
    
    grid on
    grid minor
    
    xlabel('Wavelength, nm')
    ylabel('Spectral Power Distribution, ~')
    title('Comparison of Standard Illuminants')
    
    legend({'A', 'C', 'D50', 'D55', 'D65', 'D75'},'location','north')
        
% end


















































